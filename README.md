# Partitioned pseudo-likelihood for multivariate longitudinal mixed models

This repository accompanies the manuscript **“A partitioned pseudo-likelihood framework for estimating group-specific associations in multivariate longitudinal mixed models.”**

It provides SAS programs for fitting the full-data and partitioned bivariate mixed models, combining partition-specific estimates and covariance matrices, deriving random-effects correlations, conducting canonical correlation analysis, and reproducing the simulation study with synthetic data.

## Data availability

Individual-level data from the Trøndelag Health Study (HUNT) are not distributed in this repository. Access is governed by participant consent, data-protection requirements, and HUNT data-access procedures. The public workflow uses a synthetic dataset with the same analysis-variable structure but no real participant records.

## Software

- SAS 9.4 for the local and HPC analyses.
- R 4.5.1 for publication-quality diagnostic and simulation figures.

Package and platform details are recorded in `environment/software_versions.md`.

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
3. Define `REPO_ROOT` and run `run_all_examples.sas`.

The synthetic example will generate its own data and will not read HUNT files.

The optional diagnostic-figure program is run as:

```text
Rscript code/09_create_diagnostic_figures.R input.xlsx output_directory
```

Its input workbook must contain the documented `Transformation_data` and `Residual_data` sheets. The empirical workbook is not distributed because it contains participant-level diagnostic values.

The simulation trade-off figure is generated from the aggregated simulation summary as:

```text
Rscript code/10_create_simulation_tradeoff_figure.R simulation_summary_data.json output_directory
```

When the program is sourced interactively in RStudio, it prompts for the JSON input file and the output directory.

## Reproducibility scope

The repository reproduces the statistical workflow and simulation study. Reproducing the empirical HUNT estimates requires authorized access to the study data and application of the documented analysis-variable construction.

## Citation and archived release

Citation metadata are provided in `CITATION.cff`. The development repository is available at <https://github.com/dalejo643/ppl-multivariate-longitudinal>. Version `v0.1.0` is permanently archived in Zenodo at <https://doi.org/10.5281/zenodo.21935235>.

## License

The software in this repository is distributed under the GNU General Public License v3.0 only (`GPL-3.0-only`). See `LICENSE` for the complete terms.
