/* Generate example data and fit the full model by REML and ML. */

%include "../environment/config.sas";
%include "&CODE_DIR.\01_generate_synthetic_data.sas";
%include "&CODE_DIR.\02_fit_full_model.sas";

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

%fit_full_model(data=SIMDATA.ANALYSIS_LONG,method=REML);
%fit_full_model(data=SIMDATA.ANALYSIS_LONG,method=ML);

