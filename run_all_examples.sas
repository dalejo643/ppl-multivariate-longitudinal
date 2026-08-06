/* Master validation workflow. Run SAS with the repository root as the
   current directory after creating environment/config.sas. */

%include "environment/config.sas";
%include "&CODE_DIR.\01_generate_synthetic_data.sas";
%include "&CODE_DIR.\02_fit_full_model.sas";
%include "&CODE_DIR.\03_fit_partitioned_models.sas";
%include "&CODE_DIR.\04_combine_ppl_results.sas";
%include "&CODE_DIR.\05_fit_cca.sas";
%include "&CODE_DIR.\06_bootstrap_cca.sas";

/* Prevent results from an earlier run from satisfying validation checks. */
proc datasets library=RESULTS kill nolist; quit;
proc datasets library=SIMDATA kill nolist; quit;

%generate_synthetic_data(
    out_data=SIMDATA.ANALYSIS_LONG,
    out_subjects=SIMDATA.SUBJECT_TRUTH,
    out_missing=SIMDATA.MISSING_TRUTH,
    out_summary=RESULTS.MISSING_SUMMARY,
    n_nci=498,
    n_mci=352,
    n_dem=150,
    seed=25072026,
    missing_scenario=COMPLETE
);

%fit_full_model(data=SIMDATA.ANALYSIS_LONG,method=REML);
%fit_full_model(data=SIMDATA.ANALYSIS_LONG,method=ML);

%fit_partitioned_models(
    data=SIMDATA.ANALYSIS_LONG,method=REML,
    n_partitions=6,seed=20260719
);
%combine_ppl_results(method=REML,n_partitions=6);

%fit_partitioned_models(
    data=SIMDATA.ANALYSIS_LONG,method=ML,
    n_partitions=6,seed=20260719
);
%combine_ppl_results(method=ML,n_partitions=6);

%fit_marginal_cca(data=SIMDATA.ANALYSIS_LONG);
%bootstrap_cca(
    data=SIMDATA.ANALYSIS_LONG,
    original_corr=RESULTS.CCA_CanonicalCorrelations,
    n_boot=2,
    base_seed=12082026
);

%macro require(dataset);
    %if not %sysfunc(exist(&dataset)) %then
        %put ERROR: Required output &dataset was not created.;
    %else
        %put NOTE: Verified output &dataset.;
%mend require;

%require(RESULTS.CovParms_FULL_REML);
%require(RESULTS.CombinedCovParms_REML_M6);
%require(RESULTS.CombinedCorrelations_REML_M6);
%require(RESULTS.CombinedSolutionF_REML_M6);
%require(RESULTS.CCA_CanonicalCorrelations);
%require(RESULTS.CCA_BootstrapSummary);
