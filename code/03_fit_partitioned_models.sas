/* Create balanced subject-level partitions and fit the complete model
   separately within each partition. */

%macro fit_partitioned_models(
    data=,
    output_lib=RESULTS,
    method=REML,
    n_partitions=6,
    seed=20260719,
    pid_var=ID,
    diag_var=DIAG,
    outcome_var=VAR,
    time_var=TIME,
    response_var=RESP
);

    %local iter method_up tag total_obs total_subjects start_time end_time;
    %let method_up=%upcase(&method);
    %let tag=&method_up._M&n_partitions;

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
    %if &n_partitions < 2 %then %do;
        %put ERROR: N_PARTITIONS must be at least 2.;
        %return;
    %end;

    proc datasets library=&output_lib nolist;
        delete CovParms_&tag AsyCov_&tag CovB_&tag SolutionF_&tag
               LSMeans_&tag Convergence_&tag Balance_&tag
               Performance_&tag PartitionMap_&tag;
    quit;

    /* One record per subject. DIAG is a fixed subject-level stratum. */
    proc sort data=&data(keep=&pid_var &diag_var)
              out=work._subjects nodupkey;
        by &pid_var;
    run;

    /* Reproducible random order followed by cyclic allocation within DIAG. */
    data work._subjects;
        set work._subjects;
        if _N_=1 then call streaminit(&seed);
        RandomOrder=rand('uniform');
    run;
    proc sort data=work._subjects; by &diag_var RandomOrder; run;

    data work._partition_map;
        set work._subjects;
        by &diag_var;
        retain WithinGroupIndex;
        if first.&diag_var then WithinGroupIndex=1;
        else WithinGroupIndex+1;
        Partition=mod(WithinGroupIndex-1,&n_partitions)+1;
        keep &pid_var &diag_var Partition;
    run;

    data &output_lib..PartitionMap_&tag;
        set work._partition_map;
        Method="&method_up";
        NumberPartitions=&n_partitions;
        Seed=&seed;
    run;

    proc freq data=work._partition_map noprint;
        tables Partition*&diag_var / out=&output_lib..Balance_&tag;
    run;

    proc sort data=&data out=work._analysis; by &pid_var; run;
    proc sort data=work._partition_map; by &pid_var; run;
    data work._partitioned;
        merge work._analysis(in=a)
              work._partition_map(keep=&pid_var Partition);
        by &pid_var;
        if a;
    run;

    %do iter=1 %to &n_partitions;
        data work._part;
            set work._partitioned;
            where Partition=&iter;
        run;

        proc sql noprint;
            select count(*),count(distinct &pid_var)
              into :total_obs trimmed,:total_subjects trimmed
            from work._part;
        quit;

        %let start_time=%sysfunc(datetime());

        ods output
            CovParms=work._covparms
            AsyCov=work._asycov
            CovB=work._covb
            SolutionF=work._solutionf
            LSMeans=work._lsmeans
            ConvergenceStatus=work._convergence;

        proc mixed data=work._part plots=none covtest cl ic asycov
                   method=&method_up;
            class &outcome_var &time_var(ref='0') &diag_var;

            model &response_var =
                &outcome_var*&diag_var
                &outcome_var*&time_var*&diag_var
                / noint notest solution covb;

            random &outcome_var /
                subject=&pid_var type=UN group=&diag_var g gcorr;

            repeated &outcome_var*&time_var /
                subject=&pid_var type=VC group=&outcome_var*&diag_var;

            lsmeans &outcome_var*&time_var*&diag_var / cl;
        run;
        quit;

        %let end_time=%sysfunc(datetime());

        data work._covparms;
            set work._covparms;
            ParamNumber=_N_;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
        run;
        data work._asycov;
            set work._asycov;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
        run;
        data work._covb;
            set work._covb;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
        run;
        data work._solutionf;
            set work._solutionf;
            FixedParamNumber=_N_;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
        run;
        data work._lsmeans;
            set work._lsmeans;
            LSMeanNumber=_N_;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
        run;
        data work._convergence;
            set work._convergence;
            Partition=&iter; TotalObs=&total_obs;
            TotalSubjects=&total_subjects;
            ConvergenceSuccess=(Status=0 and pdG=1 and pdH=1);
        run;
        data work._performance;
            length Method $4;
            Method="&method_up"; Partition=&iter;
            NumberPartitions=&n_partitions;
            TotalObs=&total_obs; TotalSubjects=&total_subjects;
            StartDateTime=&start_time; EndDateTime=&end_time;
            ElapsedSeconds=EndDateTime-StartDateTime;
            format StartDateTime EndDateTime datetime20.2;
        run;

        %if &iter=1 %then %do;
            data &output_lib..CovParms_&tag; set work._covparms; run;
            data &output_lib..AsyCov_&tag; set work._asycov; run;
            data &output_lib..CovB_&tag; set work._covb; run;
            data &output_lib..SolutionF_&tag; set work._solutionf; run;
            data &output_lib..LSMeans_&tag; set work._lsmeans; run;
            data &output_lib..Convergence_&tag; set work._convergence; run;
            data &output_lib..Performance_&tag; set work._performance; run;
        %end;
        %else %do;
            proc append base=&output_lib..CovParms_&tag data=work._covparms force; run;
            proc append base=&output_lib..AsyCov_&tag data=work._asycov force; run;
            proc append base=&output_lib..CovB_&tag data=work._covb force; run;
            proc append base=&output_lib..SolutionF_&tag data=work._solutionf force; run;
            proc append base=&output_lib..LSMeans_&tag data=work._lsmeans force; run;
            proc append base=&output_lib..Convergence_&tag data=work._convergence force; run;
            proc append base=&output_lib..Performance_&tag data=work._performance force; run;
        %end;

        proc datasets library=work nolist;
            delete _part _covparms _asycov _covb _solutionf _lsmeans
                   _convergence _performance;
        quit;
    %end;

    proc sort data=&output_lib..CovParms_&tag; by Partition; run;
    proc sort data=&output_lib..AsyCov_&tag; by Partition Row; run;
    proc sort data=&output_lib..CovB_&tag; by Partition Row; run;
    proc sort data=&output_lib..SolutionF_&tag; by Partition; run;
    proc sort data=&output_lib..LSMeans_&tag; by Partition; run;
    proc sort data=&output_lib..Convergence_&tag; by Partition; run;
    proc sort data=&output_lib..Performance_&tag; by Partition; run;

    proc datasets library=work nolist;
        delete _subjects _partition_map _analysis _partitioned;
    quit;

    %put NOTE: Partitioned &method_up analysis with M=&n_partitions completed.;
    %put NOTE: Combined partition outputs use tag &tag.;

%mend fit_partitioned_models;
