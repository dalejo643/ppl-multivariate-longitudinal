/* Summarize bias, RMSE, empirical variability, model-based SE and coverage. */

%macro summarize_simulation(
    input_lib=RESULTS,
    output_lib=RESULTS
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
            create table &output_lib..SimulationConvergenceSummary as
            select SampleSize,Estimator,NumberPartitions,Partition,
                   count(*) as AttemptedFits,
                   sum(ConvergenceSuccess) as SuccessfulFits,
                   mean(ConvergenceSuccess) as ConvergenceRate
            from &input_lib..SimulationConvergence
            group by SampleSize,Estimator,NumberPartitions,Partition
            order by SampleSize,Estimator,NumberPartitions,Partition;
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

%mend summarize_simulation;
