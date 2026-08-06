/* Combine the outputs created by 03_run_partitioned_example.sas. */

%include "../environment/config.sas";
%include "&CODE_DIR.\04_combine_ppl_results.sas";

%combine_ppl_results(
    input_lib=RESULTS,
    output_lib=RESULTS,
    method=REML,
    n_partitions=6
);

%combine_ppl_results(
    input_lib=RESULTS,
    output_lib=RESULTS,
    method=ML,
    n_partitions=6
);

proc print data=RESULTS.CombinedCorrelations_REML_M6 noobs; run;
proc print data=RESULTS.CombinedCorrelations_ML_M6 noobs; run;

