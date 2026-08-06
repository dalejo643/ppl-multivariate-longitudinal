/* Minimal public example: generate a synthetic dataset and inspect it. */

%include "../environment/config.sas";
%include "&CODE_DIR.\01_generate_synthetic_data.sas";

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

proc contents data=SIMDATA.ANALYSIS_LONG; run;
proc print data=RESULTS.MISSING_SUMMARY noobs; run;

