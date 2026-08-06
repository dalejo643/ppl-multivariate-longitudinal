/* Fit the full-data bivariate mixed model by ML or REML. */

%macro fit_full_model(
    data=,
    output_lib=RESULTS,
    method=REML,
    prefix=FULL,
    pid_var=ID,
    diag_var=DIAG,
    outcome_var=VAR,
    time_var=TIME,
    response_var=RESP
);

    %local method_up tag start_time end_time elapsed_seconds;
    %let method_up=%upcase(&method);
    %let tag=&prefix._&method_up;

    %if &method_up ne ML and &method_up ne REML %then %do;
        %put ERROR: METHOD must be ML or REML.;
        %return;
    %end;

    %if not %sysfunc(exist(&data)) %then %do;
        %put ERROR: Input dataset &data does not exist.;
        %return;
    %end;

    %if %sysfunc(libref(&output_lib)) ne 0 %then %do;
        %put ERROR: Output library &output_lib is not assigned.;
        %return;
    %end;

    %let start_time=%sysfunc(datetime());

    ods output
        CovParms=&output_lib..CovParms_&tag
        AsyCov=&output_lib..AsyCov_&tag
        CovB=&output_lib..CovB_&tag
        SolutionF=&output_lib..SolutionF_&tag
        LSMeans=&output_lib..LSMeans_&tag
        ConvergenceStatus=&output_lib..Convergence_&tag
        FitStatistics=&output_lib..FitStatistics_&tag
        InfoCrit=&output_lib..InfoCrit_&tag;

    proc mixed data=&data plots=none covtest cl ic asycov method=&method_up;
        class &outcome_var &time_var(ref='0') &diag_var;

        model &response_var =
            &outcome_var*&diag_var
            &outcome_var*&time_var*&diag_var
            / noint notest solution covb;

        random &outcome_var /
            subject=&pid_var
            type=UN
            group=&diag_var
            g gcorr;

        repeated &outcome_var*&time_var /
            subject=&pid_var
            type=VC
            group=&outcome_var*&diag_var;

        lsmeans &outcome_var*&time_var*&diag_var / cl;
    run;
    quit;

    %let end_time=%sysfunc(datetime());
    %let elapsed_seconds=%sysevalf(&end_time-&start_time);

    data &output_lib..Performance_&tag;
        length EstimationMethod $4 Model $32;
        EstimationMethod="&method_up";
        Model="Full-data bivariate model";
        StartDateTime=&start_time;
        EndDateTime=&end_time;
        ElapsedSeconds=&elapsed_seconds;
        format StartDateTime EndDateTime datetime20.2;
    run;

    data &output_lib..Convergence_&tag;
        set &output_lib..Convergence_&tag;
        length EstimationMethod $4;
        EstimationMethod="&method_up";
        ConvergenceSuccess=(Status=0);
    run;

    %put NOTE: Full-data &method_up model completed in &elapsed_seconds seconds.;

%mend fit_full_model;

