/* Run CCA using a previously generated synthetic dataset. */

%macro require_repo_root;
    %if not %symexist(REPO_ROOT) %then %do;
        %put ERROR: Define REPO_ROOT before running this example.;
        %abort cancel;
    %end;
%mend require_repo_root;
%require_repo_root;
%include "&REPO_ROOT.\environment\config.sas";
%include "&CODE_DIR.\05_fit_cca.sas";

%fit_marginal_cca(
    data=SIMDATA.ANALYSIS_LONG,
    output_lib=RESULTS,
    method=REML
);

proc print data=RESULTS.CCA_CanonicalCorrelations noobs; run;
