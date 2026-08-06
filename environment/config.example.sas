/* Copy this file to config.sas and edit REPO_ROOT only. */
%let REPO_ROOT=C:\path\to\reproducible_repository;
libname SIMDATA "&REPO_ROOT.\data\generated";
libname RESULTS "&REPO_ROOT.\output_examples";
%let CODE_DIR=&REPO_ROOT.\code;
%let HPC_DIR=&REPO_ROOT.\hpc;
