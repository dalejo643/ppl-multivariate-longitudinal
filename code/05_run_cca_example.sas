/* Run CCA using a previously generated synthetic dataset. */

%include "../environment/config.sas";
%include "&CODE_DIR.\05_fit_cca.sas";

%fit_marginal_cca(
    data=SIMDATA.ANALYSIS_LONG,
    output_lib=RESULTS,
    method=REML
);

proc print data=RESULTS.CCA_CanonicalCorrelations noobs; run;

