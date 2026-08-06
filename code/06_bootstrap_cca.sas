/* Stratified participant-level bootstrap for canonical correlations. */

%macro bootstrap_cca(
    data=,
    output_lib=RESULTS,
    original_corr=RESULTS.CCA_CanonicalCorrelations,
    n_boot=1000,
    base_seed=12082026,
    pid_var=ID,
    diag_var=DIAG,
    outcome_var=VAR,
    time_var=TIME,
    response_var=RESP
);

    %local brep bootseed success n_covparms n_dem n_mci n_nci;

    proc sort data=&data(keep=&pid_var &diag_var)
              out=work._subject_frame nodupkey;
        by &diag_var &pid_var;
    run;

    proc sql noprint;
        select count(*) into :n_dem trimmed
        from work._subject_frame where &diag_var='DEM';
        select count(*) into :n_mci trimmed
        from work._subject_frame where &diag_var='MCI';
        select count(*) into :n_nci trimmed
        from work._subject_frame where &diag_var='NCI';
    quit;

    proc datasets library=&output_lib nolist;
        delete CCA_BootstrapCorrelations CCA_BootstrapConvergence
               CCA_BootstrapSummary;
    quit;

    %macro _append(base=,source=);
        %if %sysfunc(exist(&base)) %then %do;
            proc append base=&base data=&source force; run;
        %end;
        %else %do;
            data &base; set &source; run;
        %end;
    %mend _append;

    %do brep=1 %to &n_boot;
        %let bootseed=%eval(&base_seed+1009*&brep);
        %let success=0;
        %let n_covparms=0;

        proc datasets library=work nolist;
            delete _boot_subjects _boot_data _boot_cov _boot_conv
                   _boot_cov_sorted _boot_matrices _boot_cancorr
                   _current_corr _current_conv;
        quit;

        proc surveyselect data=work._subject_frame
                          out=work._boot_subjects method=urs
                          samprate=1 outhits seed=&bootseed noprint;
            strata &diag_var;
        run;

        data work._boot_subjects;
            set work._boot_subjects;
            BootID=_N_;
            OriginalID=&pid_var;
            keep &diag_var OriginalID BootID;
        run;

        proc sql;
            create table work._boot_data as
            select B.BootID,A.*
            from &data as A inner join work._boot_subjects as B
              on A.&pid_var=B.OriginalID and A.&diag_var=B.&diag_var
            order by B.BootID,A.&outcome_var,A.&time_var;
        quit;

        ods exclude all;
        ods output CovParms=work._boot_cov
                   ConvergenceStatus=work._boot_conv;

        proc mixed data=work._boot_data plots=none method=REML order=internal;
            class &outcome_var &time_var(ref='0') &diag_var;
            model &response_var =
                &outcome_var*&diag_var
                &outcome_var*&time_var*&diag_var
                / noint notest solution;
            repeated &outcome_var*&time_var /
                subject=BootID type=UN group=&diag_var;
        run;
        quit;
        ods output close;
        ods exclude none;

        %if %sysfunc(exist(work._boot_conv)) %then %do;
            data work._current_conv;
                length Reason $200;
                set work._boot_conv(obs=1);
                BootstrapRep=&brep;
                BootSeed=&bootseed;
                ConvergenceSuccess=(Status=0);
            run;
            proc sql noprint;
                select max(ConvergenceSuccess) into :success trimmed
                from work._current_conv;
            quit;
        %end;
        %else %do;
            data work._current_conv;
                length Reason $200;
                BootstrapRep=&brep; BootSeed=&bootseed;
                Status=.; ConvergenceSuccess=0;
                Reason='PROC MIXED did not create convergence output';
            run;
        %end;

        %_append(base=&output_lib..CCA_BootstrapConvergence,
                 source=work._current_conv);

        %if %sysfunc(exist(work._boot_cov)) %then %do;
            proc sql noprint;
                select count(*) into :n_covparms trimmed from work._boot_cov;
            quit;
        %end;

        /* Three 5 x 5 unstructured matrices require 45 parameters. */
        %if &success=1 and &n_covparms=45 %then %do;
            proc sort data=work._boot_cov out=work._boot_cov_sorted;
                by Group;
            run;

            data work._boot_matrices(type=cov);
                length DIAG $3 _TYPE_ $8 _NAME_ $32;
                array Values[5] MOCA_0 MOCA_1 PTAU217_M1 PTAU217_0 PTAU217_1;
                array Sigma[5,5] _temporary_;
                set work._boot_cov_sorted;
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

            ods exclude all;
            ods output CanCorr=work._boot_cancorr;
            proc cancorr data=work._boot_matrices ncan=2;
                by DIAG;
                var MOCA_0 MOCA_1;
                with PTAU217_M1 PTAU217_0 PTAU217_1;
            run;
            quit;
            ods output close;
            ods exclude none;

            %if %sysfunc(exist(work._boot_cancorr)) %then %do;
                data work._current_corr;
                    set work._boot_cancorr;
                    BootstrapRep=&brep;
                    BootSeed=&bootseed;
                    keep BootstrapRep BootSeed DIAG Number CanCorr SquCanCorr;
                run;
                %_append(base=&output_lib..CCA_BootstrapCorrelations,
                         source=work._current_corr);
            %end;
        %end;

        %if %sysfunc(mod(&brep,25))=0 %then
            %put NOTE: Completed &brep of &n_boot bootstrap replicates.;
    %end;

    %if %sysfunc(exist(&output_lib..CCA_BootstrapCorrelations)) %then %do;
        proc sort data=&output_lib..CCA_BootstrapCorrelations
                  out=work._boot_first;
            by DIAG BootstrapRep;
            where Number=1;
        run;

        proc univariate data=work._boot_first noprint;
            by DIAG;
            var CanCorr;
            output out=work._boot_percentiles
                   pctlpts=2.5 97.5 pctlpre=P_;
        run;

        proc sql;
            create table work._boot_moments as
            select DIAG,count(CanCorr) as SuccessfulReplicates,
                   mean(CanCorr) as BootstrapMean,
                   std(CanCorr) as BootstrapSE
            from work._boot_first group by DIAG;

            create table &output_lib..CCA_BootstrapSummary as
            select A.DIAG,O.CanCorr as OriginalEstimate,
                   A.SuccessfulReplicates,
                   (&n_boot-A.SuccessfulReplicates) as FailedReplicates,
                   A.BootstrapMean,A.BootstrapSE,
                   (A.BootstrapMean-O.CanCorr) as BootstrapBias,
                   P.P_2_5 as PercentileLower95,
                   P.P_97_5 as PercentileUpper95
            from work._boot_moments as A
            left join &original_corr as O
              on A.DIAG=O.DIAG and O.Number=1
            left join work._boot_percentiles as P
              on A.DIAG=P.DIAG
            order by A.DIAG;
        quit;
    %end;

    proc datasets library=work nolist;
        delete _subject_frame _boot_: _current_:;
    quit;

%mend bootstrap_cca;
