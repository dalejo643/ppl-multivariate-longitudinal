/* Marginal covariance model and canonical correlation analysis.
   This analysis estimates a different association from the random-effects
   correlation and is therefore reported as complementary. */

%macro fit_marginal_cca(
    data=,
    output_lib=RESULTS,
    pid_var=ID,
    diag_var=DIAG,
    outcome_var=VAR,
    time_var=TIME,
    response_var=RESP,
    method=REML
);

    %local method_up n_dem n_mci n_nci;
    %let method_up=%upcase(&method);

    %if not %sysfunc(exist(&data)) %then %do;
        %put ERROR: Input dataset &data does not exist.;
        %return;
    %end;
    %if %sysfunc(libref(&output_lib)) ne 0 %then %do;
        %put ERROR: Output library &output_lib is not assigned.;
        %return;
    %end;

    proc sql noprint;
        select count(distinct &pid_var) into :n_dem trimmed
        from &data where &diag_var='DEM';
        select count(distinct &pid_var) into :n_mci trimmed
        from &data where &diag_var='MCI';
        select count(distinct &pid_var) into :n_nci trimmed
        from &data where &diag_var='NCI';
    quit;

    ods output
        CovParms=&output_lib..CCA_CovParms
        AsyCov=&output_lib..CCA_AsyCov
        ConvergenceStatus=&output_lib..CCA_Convergence
        SolutionF=&output_lib..CCA_SolutionF
        CovB=&output_lib..CCA_CovB
        LSMeans=&output_lib..CCA_LSMeans
        FitStatistics=&output_lib..CCA_FitStatistics;

    proc mixed data=&data plots=none covtest cl ic asycov
               method=&method_up order=internal;
        class &outcome_var &time_var(ref='0') &diag_var;
        model &response_var =
            &outcome_var*&diag_var
            &outcome_var*&time_var*&diag_var
            / noint notest solution covb;
        repeated &outcome_var*&time_var /
            subject=&pid_var type=UN group=&diag_var;
        lsmeans &outcome_var*&time_var*&diag_var / cl;
    run;
    quit;

    /* Required order of the five observed measurements. */
    data &output_lib..CCA_LevelOrder;
        length Variable $8 Label $32;
        Position=1; Variable='MOCA'; Time=0; Label='MOCA_TIME_0'; output;
        Position=2; Variable='MOCA'; Time=1; Label='MOCA_TIME_1'; output;
        Position=3; Variable='PTAU217'; Time=-1; Label='PTAU217_TIME_M1'; output;
        Position=4; Variable='PTAU217'; Time=0; Label='PTAU217_TIME_0'; output;
        Position=5; Variable='PTAU217'; Time=1; Label='PTAU217_TIME_1'; output;
    run;

    proc sort data=&output_lib..CCA_CovParms out=work._cca_covparms;
        by Group;
    run;

    /* Reconstruct one symmetric 5 x 5 TYPE=COV matrix per stratum. */
    data &output_lib..CCA_CovarianceMatrices(type=cov);
        length DIAG $3 _TYPE_ $8 _NAME_ $32;
        array Values[5] MOCA_0 MOCA_1 PTAU217_M1 PTAU217_0 PTAU217_1;
        array Sigma[5,5] _temporary_;
        set work._cca_covparms;
        by Group;

        if first.Group then do RowIndex=1 to 5;
            do ColIndex=1 to 5;
                Sigma[RowIndex,ColIndex]=.;
            end;
        end;

        RowIndex=input(scan(CovParm,2,'(,)'),best.);
        ColIndex=input(scan(CovParm,3,'(,)'),best.);
        Sigma[RowIndex,ColIndex]=Estimate;
        Sigma[ColIndex,RowIndex]=Estimate;

        if last.Group then do;
            DIAG=scan(Group,-1,' ');
            _TYPE_='COV';
            do MatrixRow=1 to 5;
                _NAME_=vname(Values[MatrixRow]);
                do MatrixCol=1 to 5;
                    Values[MatrixCol]=Sigma[MatrixRow,MatrixCol];
                end;
                output;
            end;

            if DIAG='DEM' then NGroup=&n_dem;
            else if DIAG='MCI' then NGroup=&n_mci;
            else NGroup=&n_nci;
            _TYPE_='N';
            _NAME_=' ';
            do MatrixCol=1 to 5;
                Values[MatrixCol]=NGroup;
            end;
            output;
        end;

        keep DIAG _TYPE_ _NAME_ MOCA_0 MOCA_1
             PTAU217_M1 PTAU217_0 PTAU217_1;
    run;

    ods output
        CanCorr=&output_lib..CCA_CanonicalCorrelations
        RawCanCoefV=&output_lib..CCA_RawCoefficients_MOCA
        RawCanCoefW=&output_lib..CCA_RawCoefficients_PTAU217
        StdCanCoefV=&output_lib..CCA_StdCoefficients_MOCA
        StdCanCoefW=&output_lib..CCA_StdCoefficients_PTAU217
        CanStructureVCan=&output_lib..CCA_Structure_MOCA
        CanStructureWCan=&output_lib..CCA_Structure_PTAU217;

    proc cancorr data=&output_lib..CCA_CovarianceMatrices ncan=2
                 vprefix=MOCA_CAN wprefix=PTAU_CAN
                 vname='MoCA measurements'
                 wname='p-tau217 measurements';
        by DIAG;
        var MOCA_0 MOCA_1;
        with PTAU217_M1 PTAU217_0 PTAU217_1;
    run;
    quit;

    ods output close;
    proc datasets library=work nolist; delete _cca_covparms; quit;

    %put NOTE: Marginal covariance model and CCA completed.;

%mend fit_marginal_cca;
