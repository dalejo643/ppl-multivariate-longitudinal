/* Validation example. Increase N_BOOT only after this run succeeds. */

%include "../environment/config.sas";
%include "&CODE_DIR.\06_bootstrap_cca.sas";

%bootstrap_cca(
    data=SIMDATA.ANALYSIS_LONG,
    output_lib=RESULTS,
    original_corr=RESULTS.CCA_CanonicalCorrelations,
    n_boot=20,
    base_seed=12082026
);

proc print data=RESULTS.CCA_BootstrapSummary noobs; run;

