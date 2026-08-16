/* Summarize bias, RMSE, empirical variability, model-based SE and coverage. */

%macro summarize_simulation(
    input_lib=RESULTS,
    output_lib=RESULTS,
    tradeoff_csv=
);

    %if %sysfunc(exist(&input_lib..SimulationCovParms)) %then %do;
        proc sql;
            create table &output_lib..SimulationCovSummary as
            select SampleSize,Estimator,NumberPartitions,
                   ParamNumber,DiagnosticGroup,ParameterType,TrueValue,
                   count(Estimate) as SuccessfulReplicates,
                   mean(Estimate) as MeanEstimate,
                   mean(Error) as Bias,
                   sqrt(mean(SquaredError)) as RMSE,
                   std(Estimate) as EmpiricalSD,
                   mean(StdErr) as MeanModelSE,
                   mean(abs(Error)<=1.959964*StdErr) as Coverage95
            from &input_lib..SimulationCovParms
            where not missing(Estimate)
            group by SampleSize,Estimator,NumberPartitions,
                     ParamNumber,DiagnosticGroup,ParameterType,TrueValue
            order by SampleSize,ParamNumber,Estimator,NumberPartitions;
        quit;
    %end;

    %if %sysfunc(exist(&input_lib..SimulationCorrelations)) %then %do;
        proc sql;
            create table &output_lib..SimulationCorrelationSummary as
            select SampleSize,Estimator,NumberPartitions,
                   DiagnosticGroup,TrueValue,
                   count(Estimate) as SuccessfulReplicates,
                   mean(Estimate) as MeanEstimate,
                   mean(Error) as Bias,
                   sqrt(mean(SquaredError)) as RMSE,
                   std(Estimate) as EmpiricalSD,
                   mean(StdErr) as MeanModelSE,
                   mean(abs(Error)<=1.959964*StdErr) as Coverage95
            from &input_lib..SimulationCorrelations
            where not missing(Estimate)
            group by SampleSize,Estimator,NumberPartitions,
                     DiagnosticGroup,TrueValue
            order by SampleSize,DiagnosticGroup,Estimator,NumberPartitions;
        quit;
    %end;

    %if %sysfunc(exist(&input_lib..SimulationConvergence)) %then %do;
        proc sql;
            create table work._convergence_by_rep as
            select SampleSize,Estimator,NumberPartitions,Replicate,
                   min(ConvergenceSuccess) as CompleteConvergence
            from &input_lib..SimulationConvergence
            group by SampleSize,Estimator,NumberPartitions,Replicate;

            create table &output_lib..SimulationConvergenceSummary as
            select SampleSize,Estimator,NumberPartitions,
                   count(*) as AttemptedReplicates,
                   sum(CompleteConvergence) as CompleteReplicates,
                   100*mean(CompleteConvergence) as ConvergencePercent
            from work._convergence_by_rep
            group by SampleSize,Estimator,NumberPartitions
            order by SampleSize,Estimator,NumberPartitions;
        quit;
    %end;

    %if %sysfunc(exist(&input_lib..SimulationPerformance)) %then %do;
        proc sql;
            create table work._runtime_by_rep as
            select SampleSize,Estimator,NumberPartitions,Replicate,
                   sum(ElapsedSeconds) as TotalSequentialSeconds,
                   max(ElapsedSeconds) as MaximumSingleFitSeconds
            from &input_lib..SimulationPerformance
            group by SampleSize,Estimator,NumberPartitions,Replicate;

            create table &output_lib..SimulationPerformanceSummary as
            select SampleSize,Estimator,NumberPartitions,
                   count(*) as Replicates,
                   mean(TotalSequentialSeconds) as MeanSequentialSeconds,
                   median(TotalSequentialSeconds) as MedianSequentialSeconds,
                   max(TotalSequentialSeconds) as MaximumSequentialSeconds,
                   mean(MaximumSingleFitSeconds) as MeanMaximumFitSeconds
            from work._runtime_by_rep
            group by SampleSize,Estimator,NumberPartitions
            order by SampleSize,Estimator,NumberPartitions;
        quit;
        proc datasets library=work nolist; delete _runtime_by_rep; quit;
    %end;

    %if %sysfunc(exist(&output_lib..SimulationCorrelationSummary)) and
        %sysfunc(exist(&output_lib..SimulationConvergenceSummary)) and
        %sysfunc(exist(&output_lib..SimulationPerformanceSummary)) %then %do;
        proc sql;
            create table work._maximum_correlation_bias as
            select SampleSize,Estimator,NumberPartitions,
                   max(abs(Bias)) as MaximumAbsoluteCorrelationBias
            from &output_lib..SimulationCorrelationSummary
            group by SampleSize,Estimator,NumberPartitions;

            create table &output_lib..TradeoffSummary as
            select C.SampleSize as N,
                   C.NumberPartitions as M,
                   C.Estimator,
                   C.ConvergencePercent,
                   B.MaximumAbsoluteCorrelationBias,
                   P.MedianSequentialSeconds as MedianSeconds,
                   F.MedianSequentialSeconds/P.MedianSequentialSeconds
                       as Speedup
            from &output_lib..SimulationConvergenceSummary as C
            inner join work._maximum_correlation_bias as B
                on C.SampleSize=B.SampleSize
               and C.Estimator=B.Estimator
               and C.NumberPartitions=B.NumberPartitions
            inner join &output_lib..SimulationPerformanceSummary as P
                on C.SampleSize=P.SampleSize
               and C.Estimator=P.Estimator
               and C.NumberPartitions=P.NumberPartitions
            left join &output_lib..SimulationPerformanceSummary as F
                on C.SampleSize=F.SampleSize
               and F.Estimator="Full REML"
               and F.NumberPartitions=1
            order by N,M;
        quit;

        %if %length(%superq(tradeoff_csv)) %then %do;
            proc export
                data=&output_lib..TradeoffSummary
                outfile="&tradeoff_csv"
                dbms=csv
                replace;
            run;
        %end;

        proc datasets library=work nolist;
            delete _maximum_correlation_bias _convergence_by_rep;
        quit;
    %end;

%mend summarize_simulation;
