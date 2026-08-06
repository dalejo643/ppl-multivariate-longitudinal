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
2. Confirm 15 covariance parameters in identical order for every partition.
3. Compare public PPL outputs with one previously audited empirical configuration.
4. Confirm the five-measurement CCA order from the SAS class-level output.
5. [Partially completed] The public bootstrap workflow was validated with two replications. A 20-replication release check remains recommended.
6. Run a two-replication simulation validation.
7. Record exact software versions.
8. Obtain coauthor and KU Leuven approval for the intended dual-license model and definitive legal text.
9. Replace GitHub placeholders in `CITATION.cff` and `README.md`.
10. Scan the final Git history, not only the working tree, for restricted files.
