/* Run one sequential block of simulation replications.
   Independent blocks can be distributed through a Slurm job array. */

%macro run_simulation_batch(
    output_lib=RESULTS,
    sample_size=5000,
    first_rep=1,
    last_rep=5,
    base_seed=31072026,
    missing_scenario=HUNT_MAR,
    partitions=2 4 6
);

    %local rep seed n_nci n_mci n_dem k m;
    %let n_nci=%sysfunc(round(%sysevalf(&sample_size*0.498)));
    %let n_mci=%sysfunc(round(%sysevalf(&sample_size*0.352)));
    %let n_dem=%eval(&sample_size-&n_nci-&n_mci);

    %macro _append(base=,source=);
        %if %sysfunc(exist(&base)) %then %do;
            proc append base=&base data=&source force; run;
        %end;
        %else %do;
            data &base; set &source; run;
        %end;
    %mend _append;

    /* The 15 covariance parameters in the model's verified output order. */
    data work._true_cov;
        length DiagnosticGroup $3 ParameterType $12;
        input ParameterIndex DiagnosticGroup $ ParameterType $ TrueValue;
        datalines;
1 DEM Variance1 0.17160
2 DEM Covariance 0.09555
3 DEM Variance2 0.30970
4 MCI Variance1 0.19880
5 MCI Covariance 0.06981
6 MCI Variance2 0.24430
7 NCI Variance1 0.19630
8 NCI Covariance 0.05728
9 NCI Variance2 0.24240
10 DEM Residual1 0.20130
11 MCI Residual1 0.19620
12 NCI Residual1 0.23840
13 DEM Residual2 0.10700
14 MCI Residual2 0.07590
15 NCI Residual2 0.05681
;
    run;

    data work._true_corr;
        length DiagnosticGroup $3;
        input DiagnosticGroup $ TrueValue;
        datalines;
DEM 0.4145
MCI 0.3168
NCI 0.2626
;
    run;

    %do rep=&first_rep %to &last_rep;
        %let seed=%eval(&base_seed+1009*&rep);

        %generate_synthetic_data(
            out_data=work._sim_long,
            out_subjects=work._sim_subjects,
            out_missing=work._sim_missing,
            out_summary=work._sim_missing_summary,
            n_nci=&n_nci,
            n_mci=&n_mci,
            n_dem=&n_dem,
            seed=&seed,
            missing_scenario=&missing_scenario
        );

        /* Full-data REML reference. */
        %fit_full_model(
            data=work._sim_long,
            output_lib=work,
            method=REML,
            prefix=SIMFULL
        );

        data work._full_cov;
            merge work.CovParms_SIMFULL_REML(in=a)
                  work._true_cov(rename=(ParameterIndex=ParamNumber));
            ParamNumber=_N_;
            if a;
            length Estimator $12 Method $4;
            Estimator='Full REML'; Method='REML';
            Replicate=&rep; SampleSize=&sample_size; NumberPartitions=1;
            SimulationSeed=&seed;
            Error=Estimate-TrueValue;
            SquaredError=Error**2;
        run;
        %_append(base=&output_lib..SimulationCovParms,source=work._full_cov);

        data work._full_corr;
            array Theta[9] _temporary_;
            do ParameterIndex=1 to 9;
                set work.CovParms_SIMFULL_REML point=ParameterIndex;
                Theta[ParameterIndex]=Estimate;
            end;
            do GroupIndex=1 to 3;
                if GroupIndex=1 then DiagnosticGroup='DEM';
                else if GroupIndex=2 then DiagnosticGroup='MCI';
                else DiagnosticGroup='NCI';
                StartParameter=1+3*(GroupIndex-1);
                Estimate=Theta[StartParameter+1]/
                    sqrt(Theta[StartParameter]*Theta[StartParameter+2]);
                Replicate=&rep; SampleSize=&sample_size;
                NumberPartitions=1; SimulationSeed=&seed;
                Estimator='Full REML'; Method='REML';
                StdErr=.;
                output;
            end;
            keep Replicate SampleSize NumberPartitions SimulationSeed
                 Estimator Method DiagnosticGroup Estimate StdErr;
            stop;
        run;
        proc sql;
            create table work._full_corr2 as
            select A.*,B.TrueValue,A.Estimate-B.TrueValue as Error,
                   (A.Estimate-B.TrueValue)**2 as SquaredError
            from work._full_corr as A left join work._true_corr as B
              on A.DiagnosticGroup=B.DiagnosticGroup;
        quit;
        %_append(base=&output_lib..SimulationCorrelations,
                 source=work._full_corr2);

        data work._full_performance;
            set work.Performance_SIMFULL_REML;
            Replicate=&rep; SampleSize=&sample_size;
            NumberPartitions=1; SimulationSeed=&seed;
            Estimator='Full REML';
        run;
        %_append(base=&output_lib..SimulationPerformance,
                 source=work._full_performance);

        /* Partitioned REML configurations. */
        %let k=1;
        %do %while(%scan(&partitions,&k,%str( )) ne %str());
            %let m=%scan(&partitions,&k,%str( ));

            %fit_partitioned_models(
                data=work._sim_long,
                output_lib=work,
                method=REML,
                n_partitions=&m,
                seed=%eval(&seed+700001)
            );
            %combine_ppl_results(
                input_lib=work,
                output_lib=work,
                method=REML,
                n_partitions=&m
            );

            data work._ppl_cov;
                merge work.CombinedCovParms_REML_M&m(in=a)
                      work._true_cov(rename=(ParameterIndex=ParamNumber));
                by ParamNumber;
                if a;
                length Estimator $12;
                Estimator='PPL-REML';
                Replicate=&rep; SampleSize=&sample_size;
                SimulationSeed=&seed;
                Estimate=Estimate_PPL;
                StdErr=StdErr_PPL;
                Error=Estimate-TrueValue;
                SquaredError=Error**2;
            run;
            %_append(base=&output_lib..SimulationCovParms,source=work._ppl_cov);

            proc sql;
                create table work._ppl_corr as
                select &rep as Replicate,&sample_size as SampleSize,
                       A.NumberPartitions,&seed as SimulationSeed,
                       'PPL-REML' as Estimator length=12,
                       A.Method,A.DiagnosticGroup,
                       A.Correlation_PPL as Estimate,
                       A.StdErr_Correlation as StdErr,
                       B.TrueValue,
                       A.Correlation_PPL-B.TrueValue as Error,
                       (A.Correlation_PPL-B.TrueValue)**2 as SquaredError
                from work.CombinedCorrelations_REML_M&m as A
                left join work._true_corr as B
                  on A.DiagnosticGroup=B.DiagnosticGroup;
            quit;
            %_append(base=&output_lib..SimulationCorrelations,
                     source=work._ppl_corr);

            data work._ppl_performance;
                set work.Performance_REML_M&m;
                Replicate=&rep; SampleSize=&sample_size;
                SimulationSeed=&seed;
                Estimator='PPL-REML';
            run;
            %_append(base=&output_lib..SimulationPerformance,
                     source=work._ppl_performance);

            data work._ppl_convergence;
                set work.Convergence_REML_M&m;
                Replicate=&rep; SampleSize=&sample_size;
                SimulationSeed=&seed;
                Estimator='PPL-REML';
            run;
            %_append(base=&output_lib..SimulationConvergence,
                     source=work._ppl_convergence);

            %let k=%eval(&k+1);
        %end;

        data work._missing_rep;
            set work._sim_missing_summary;
            Replicate=&rep; SampleSize=&sample_size; SimulationSeed=&seed;
            MissingScenario="%upcase(&missing_scenario)";
        run;
        %_append(base=&output_lib..SimulationMissingness,
                 source=work._missing_rep);

        proc datasets library=work nolist;
            delete _sim_: _full_: _ppl_: CovParms_SIMFULL_REML
                   AsyCov_SIMFULL_REML CovB_SIMFULL_REML
                   SolutionF_SIMFULL_REML LSMeans_SIMFULL_REML
                   Convergence_SIMFULL_REML FitStatistics_SIMFULL_REML
                   InfoCrit_SIMFULL_REML Performance_SIMFULL_REML;
        quit;

        %put NOTE: Completed replication &rep of this batch.;
    %end;

    proc datasets library=work nolist; delete _true_cov _true_corr; quit;

%mend run_simulation_batch;
