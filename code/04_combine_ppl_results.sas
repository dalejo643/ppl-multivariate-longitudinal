/* Combine independent partition estimates and their covariance matrices. */

%macro combine_ppl_results(
    input_lib=RESULTS,
    output_lib=RESULTS,
    method=REML,
    n_partitions=6,
    diag_var=DIAG,
    outcome_var=VAR,
    time_var=TIME
);

    %local method_up tag q_cov q_fixed failed incomplete j;
    %let method_up=%upcase(&method);
    %let tag=&method_up._M&n_partitions;

    %if &method_up ne ML and &method_up ne REML %then %do;
        %put ERROR: METHOD must be ML or REML.;
        %return;
    %end;
    %if not %sysfunc(exist(&input_lib..CovParms_&tag)) or
        not %sysfunc(exist(&input_lib..AsyCov_&tag)) %then %do;
        %put ERROR: CovParms_&tag and AsyCov_&tag are required.;
        %return;
    %end;

    proc sql noprint;
        select count(*) into :failed trimmed
        from &input_lib..Convergence_&tag
        where Status ne 0;

        select max(ParamNumber) into :q_cov trimmed
        from &input_lib..CovParms_&tag;

        select count(*) into :incomplete trimmed
        from (
            select ParamNumber,count(distinct Partition) as NumberFound
            from &input_lib..CovParms_&tag
            group by ParamNumber
            having calculated NumberFound ne &n_partitions
        );
    quit;

    %if &failed > 0 %then %do;
        %put ERROR: &failed partition-specific models did not converge.;
        %return;
    %end;
    %if &incomplete > 0 %then %do;
        %put ERROR: Parameter order or availability differs across partitions.;
        %return;
    %end;

    /* Var(mean(theta_m)) = sum(Sigma_m)/M**2 = mean(Sigma_m)/M. */
    proc sql;
        create table &output_lib..CombinedAsyCov_&tag as
        select Row,CovParm
        %do j=1 %to &q_cov;
            ,mean(CovP&j)/&n_partitions as CovP&j
        %end;
            ,"&method_up" as Method length=4,
             &n_partitions as NumberPartitions
        from &input_lib..AsyCov_&tag
        group by Row,CovParm
        order by Row;
    quit;

    data work._cov_diagonal;
        set &output_lib..CombinedAsyCov_&tag;
        array C[&q_cov] CovP1-CovP&q_cov;
        ParamNumber=Row;
        Variance_PPL=C[Row];
        StdErr_PPL=sqrt(Variance_PPL);
        keep ParamNumber Variance_PPL StdErr_PPL;
    run;

    proc sql;
        create table work._cov_estimates as
        select ParamNumber,CovParm,Subject,Group,
               mean(Estimate) as Estimate_PPL,
               count(Estimate) as NumberEstimates,
               "&method_up" as Method length=4,
               &n_partitions as NumberPartitions
        from &input_lib..CovParms_&tag
        group by ParamNumber,CovParm,Subject,Group
        order by ParamNumber;
    quit;

    data &output_lib..CombinedCovParms_&tag;
        merge work._cov_estimates work._cov_diagonal;
        by ParamNumber;
        if StdErr_PPL>0 then ZValue_PPL=Estimate_PPL/StdErr_PPL;
        format Estimate_PPL StdErr_PPL Variance_PPL ZValue_PPL 12.8;
    run;

    /* Applied-model order: 1-3 DEM, 4-6 MCI, 7-9 NCI.
       Each triplet is d11, d12, d22. */
    %if &q_cov < 9 %then %do;
        %put ERROR: At least nine covariance parameters are required.;
        %return;
    %end;

    data &output_lib..CombinedCorrelations_&tag;
        length DiagnosticGroup $3 Method $4;
        array Theta[&q_cov] _temporary_;
        array C[&q_cov] CovP1-CovP&q_cov;

        do ParameterIndex=1 to &q_cov;
            set &output_lib..CombinedCovParms_&tag point=ParameterIndex;
            Theta[ParameterIndex]=Estimate_PPL;
        end;

        do GroupIndex=1 to 3;
            StartParameter=1+3*(GroupIndex-1);
            if GroupIndex=1 then DiagnosticGroup='DEM';
            else if GroupIndex=2 then DiagnosticGroup='MCI';
            else DiagnosticGroup='NCI';

            d11=Theta[StartParameter];
            d12=Theta[StartParameter+1];
            d22=Theta[StartParameter+2];

            RowToRead=StartParameter;
            set &output_lib..CombinedAsyCov_&tag point=RowToRead;
            v11=C[StartParameter];
            v12=C[StartParameter+1];
            v13=C[StartParameter+2];

            RowToRead=StartParameter+1;
            set &output_lib..CombinedAsyCov_&tag point=RowToRead;
            v22=C[StartParameter+1];
            v23=C[StartParameter+2];

            RowToRead=StartParameter+2;
            set &output_lib..CombinedAsyCov_&tag point=RowToRead;
            v33=C[StartParameter+2];

            Correlation_PPL=d12/sqrt(d11*d22);
            g11=-Correlation_PPL/(2*d11);
            g12=1/sqrt(d11*d22);
            g22=-Correlation_PPL/(2*d22);

            Variance_Correlation=
                g11**2*v11+g12**2*v22+g22**2*v33
                +2*g11*g12*v12+2*g11*g22*v13+2*g12*g22*v23;
            StdErr_Correlation=sqrt(Variance_Correlation);
            Method="&method_up";
            NumberPartitions=&n_partitions;
            output;
        end;

        keep DiagnosticGroup Method NumberPartitions d11 d12 d22
             Correlation_PPL Variance_Correlation StdErr_Correlation;
        format d11 d12 d22 Correlation_PPL Variance_Correlation
               StdErr_Correlation 12.8;
        stop;
    run;

    /* Combine the fixed-effects covariance matrix and estimates. */
    %if %sysfunc(exist(&input_lib..CovB_&tag)) and
        %sysfunc(exist(&input_lib..SolutionF_&tag)) %then %do;

        proc sql noprint;
            select max(FixedParamNumber) into :q_fixed trimmed
            from &input_lib..SolutionF_&tag;
        quit;

        proc sql;
            create table &output_lib..CombinedCovB_&tag as
            select Row,Effect,&outcome_var,&time_var,&diag_var
            %do j=1 %to &q_fixed;
                ,mean(Col&j)/&n_partitions as Col&j
            %end;
                ,"&method_up" as Method length=4,
                 &n_partitions as NumberPartitions
            from &input_lib..CovB_&tag
            group by Row,Effect,&outcome_var,&time_var,&diag_var
            order by Row;
        quit;

        data work._fixed_diagonal;
            set &output_lib..CombinedCovB_&tag;
            array C[&q_fixed] Col1-Col&q_fixed;
            FixedParamNumber=Row;
            Variance_PPL=C[Row];
            StdErr_PPL=sqrt(Variance_PPL);
            keep FixedParamNumber Variance_PPL StdErr_PPL;
        run;

        proc sql;
            create table work._fixed_estimates as
            select FixedParamNumber,Effect,&outcome_var,&time_var,&diag_var,
                   mean(Estimate) as Estimate_PPL,
                   count(Estimate) as NumberEstimates,
                   "&method_up" as Method length=4,
                   &n_partitions as NumberPartitions
            from &input_lib..SolutionF_&tag
            group by FixedParamNumber,Effect,&outcome_var,&time_var,&diag_var
            order by FixedParamNumber;
        quit;

        data &output_lib..CombinedSolutionF_&tag;
            merge work._fixed_estimates work._fixed_diagonal;
            by FixedParamNumber;
            if StdErr_PPL>0 then tValue_PPL=Estimate_PPL/StdErr_PPL;
        run;
    %end;

    /* Marginal standard errors suffice for the supplementary LSMeans table. */
    %if %sysfunc(exist(&input_lib..LSMeans_&tag)) %then %do;
        proc sql;
            create table &output_lib..CombinedLSMeans_&tag as
            select LSMeanNumber,Effect,&outcome_var,&time_var,&diag_var,
                   mean(Estimate) as Estimate_PPL,
                   sqrt(sum(StdErr**2))/&n_partitions as StdErr_PPL,
                   count(Estimate) as NumberEstimates,
                   "&method_up" as Method length=4,
                   &n_partitions as NumberPartitions
            from &input_lib..LSMeans_&tag
            group by LSMeanNumber,Effect,&outcome_var,&time_var,&diag_var
            order by LSMeanNumber;
        quit;
    %end;

    proc datasets library=work nolist;
        delete _cov_diagonal _cov_estimates _fixed_diagonal _fixed_estimates;
    quit;

    %put NOTE: PPL combination completed for &tag.;

%mend combine_ppl_results;
