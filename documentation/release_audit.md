# Release audit

## Completed structural checks

- Public programs contain no local HUNT paths, HPC usernames, email addresses, or allocation identifiers.
- Restricted HUNT records and original data-management programs are excluded.
- ML and REML use the same fixed, random, and residual specifications.
- ML and REML partitions are reproducible through a common seed.
- PPL combines complete covariance matrices rather than averaging standard errors.
- Random-effects correlations are calculated after combining covariance components.
- CCA uses a separate marginal covariance model and participant-level bootstrap.
- The simulation reuses the public generator and model-fitting modules.
- One HPC array task corresponds to one simulation replication.

## Checks required before public release

1. [Completed 2026-08-06] `run_all_examples.sas` ran locally with zero errors and zero warnings, and all required outputs were verified.
2. [Completed 2026-08-14] Confirmed 15 covariance parameters in identical order for all six ML and REML partitions; every partition-specific `ASYCOV` matrix has 15 rows and 15 covariance columns.
3. [Completed 2026-08-14] The public PPL modules were rerun on the audited empirical REML configuration with M=6 and seed 20260719. All 15 covariance-parameter estimates and standard errors, together with the three derived random-effect correlations and their standard errors, agreed with the archived results within 1e-7. The validation log contained zero errors and zero warnings.
4. [Completed 2026-08-14] Confirmed the five-measurement CCA order: MoCA at times 0 and 1, followed by p-tau217 at times -1, 0, and 1.
5. [Completed 2026-08-14] The public bootstrap workflow was validated with 20 replications. All 20 converged and contributed results for each diagnostic stratum.
6. [Completed 2026-08-14] The public simulation workflow was validated with two replications and partition counts M=2, 4, and 6. All five expected output datasets were produced with the required replication and partition identifiers. The validation also confirmed that non-positive-definite G or Hessian diagnostics are retained in the convergence output rather than silently classified as successful fits.
7. [Completed 2026-08-14] Recorded SAS 9.4 for both local and HPC analyses and R 4.5.1 with the figure-generation package versions.
8. [Completed 2026-08-14] GPL-3.0-only was selected by the corresponding author under the coauthors' delegation. The official unmodified GPL v3 text was added, and the provisional dual-license files and metadata were removed.
9. [Completed 2026-08-14] Confirmed the GitHub repository URL in `CITATION.cff` and `README.md`; no unresolved repository placeholders remain.
10. [Ready for final confirmation] The working tree and existing one-commit history were scanned for restricted filenames, HUNT paths, HPC identifiers, personal email addresses, and local user paths. No matches were found. Repeat the history scan after committing the release changes.
