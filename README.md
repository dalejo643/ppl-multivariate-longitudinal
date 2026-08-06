# Partitioned pseudo-likelihood for multivariate longitudinal mixed models

This repository accompanies the manuscript **“A partitioned pseudo-likelihood framework for estimating group-specific associations in multivariate longitudinal mixed models.”**

It provides SAS programs for fitting the full-data and partitioned bivariate mixed models, combining partition-specific estimates and covariance matrices, deriving random-effects correlations, conducting canonical correlation analysis, and reproducing the simulation study with synthetic data.

## Data availability

Individual-level data from the Trøndelag Health Study (HUNT) are not distributed in this repository. Access is governed by participant consent, data-protection requirements, and HUNT data-access procedures. The public workflow uses a synthetic dataset with the same analysis-variable structure but no real participant records.

## Software

- SAS 9.4
- R is used only for publication-quality diagnostic figures.

Exact software information will be recorded in `environment/software_versions.md` before archival release.

## Repository structure

```text
code/             Reusable SAS and R programs
data/             Synthetic-data documentation and generated files
documentation/    Workflow, estimands, and code inventory
environment/      User-editable path configuration and software versions
hpc/              Generic Slurm templates for the simulation
output_examples/  Small outputs generated from synthetic data
```

## Quick start

1. Copy `environment/config.example.sas` to `environment/config.sas`.
2. Edit the root directory in `config.sas`.
3. Run `code/00_run_synthetic_example.sas`.

The synthetic example will generate its own data and will not read HUNT files.

## Reproducibility scope

The repository reproduces the statistical workflow and simulation study. Reproducing the empirical HUNT estimates requires authorized access to the study data and application of the documented analysis-variable construction.

## Citation and archived release

Citation metadata are provided in `CITATION.cff`. After coauthor approval, a versioned release will be archived in Zenodo and the DOI will be added here and to the manuscript.

## License status

The intended model is dual licensing: non-commercial academic use under defined research terms and a separate license for commercial use. No reuse rights are granted while the definitive terms remain under institutional and coauthor review. See `LICENSE_PENDING.md`.
