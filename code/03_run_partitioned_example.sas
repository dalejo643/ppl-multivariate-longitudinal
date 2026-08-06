/* Fit the public synthetic example using the same partitions for ML and REML. */

%include "../environment/config.sas";
%include "&CODE_DIR.\01_generate_synthetic_data.sas";
%include "&CODE_DIR.\03_fit_partitioned_models.sas";

%generate_synthetic_data(
    out_data=SIMDATA.ANALYSIS_LONG,
    out_subjects=SIMDATA.SUBJECT_TRUTH,
    out_missing=SIMDATA.MISSING_TRUTH,
    out_summary=RESULTS.MISSING_SUMMARY,
    n_nci=498,
    n_mci=352,
    n_dem=150,
    seed=25072026,
    missing_scenario=HUNT_MAR
);

%fit_partitioned_models(
    data=SIMDATA.ANALYSIS_LONG,
    output_lib=RESULTS,
    method=REML,
    n_partitions=6,
    seed=20260719
);

%fit_partitioned_models(
    data=SIMDATA.ANALYSIS_LONG,
    output_lib=RESULTS,
    method=ML,
    n_partitions=6,
    seed=20260719
);

