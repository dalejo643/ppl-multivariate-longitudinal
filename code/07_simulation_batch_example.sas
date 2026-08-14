/* Small validation batch. This is not the final simulation design. */

%macro require_repo_root;
    %if not %symexist(REPO_ROOT) %then %do;
        %put ERROR: Define REPO_ROOT before running this example.;
        %abort cancel;
    %end;
%mend require_repo_root;
%require_repo_root;
%include "&REPO_ROOT.\environment\config.sas";
%include "&CODE_DIR.\01_generate_synthetic_data.sas";
%include "&CODE_DIR.\02_fit_full_model.sas";
%include "&CODE_DIR.\03_fit_partitioned_models.sas";
%include "&CODE_DIR.\04_combine_ppl_results.sas";
%include "&CODE_DIR.\07_run_simulation_batch.sas";

/* Prevent an earlier validation run from being appended to this one. */
proc datasets library=RESULTS nolist;
    delete SimulationCovParms SimulationCorrelations
           SimulationPerformance SimulationConvergence
           SimulationMissingness;
quit;

%run_simulation_batch(
    output_lib=RESULTS,
    sample_size=1000,
    first_rep=1,
    last_rep=2,
    base_seed=31072026,
    missing_scenario=HUNT_MAR,
    partitions=2 4 6
);
