/* Environment variables are supplied by the Slurm batch file. */

%let REPO_ROOT=%sysget(REPO_ROOT);
%let SIM_OUTPUT=%sysget(SIM_OUTPUT);
%let SIM_N=%sysget(SIM_N);
%let ARRAY_TASK=%sysget(SLURM_ARRAY_TASK_ID);
%let FIRST_REP=&ARRAY_TASK;
%let LAST_REP=&ARRAY_TASK;

libname RESULTS "&SIM_OUTPUT";
%let CODE_DIR=&REPO_ROOT./code;

%include "&CODE_DIR./01_generate_synthetic_data.sas";
%include "&CODE_DIR./02_fit_full_model.sas";
%include "&CODE_DIR./03_fit_partitioned_models.sas";
%include "&CODE_DIR./04_combine_ppl_results.sas";
%include "&CODE_DIR./07_run_simulation_batch.sas";

%run_simulation_batch(
    output_lib=RESULTS,
    sample_size=&SIM_N,
    first_rep=&FIRST_REP,
    last_rep=&LAST_REP,
    base_seed=31072026,
    missing_scenario=HUNT_MAR,
    partitions=2 4 6
);
