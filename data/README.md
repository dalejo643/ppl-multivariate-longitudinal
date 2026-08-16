# Synthetic data

No HUNT participant data are included or read by the public workflow.

`code/01_generate_synthetic_data.sas` creates long-format synthetic data with the following primary variables:

| Variable | Description |
|---|---|
| `ID` | Synthetic participant identifier |
| `DIAG` | Fixed diagnostic stratum: NCI, MCI, or DEM |
| `VAR` | Outcome indicator: MOCA or PTAU217 |
| `TIME` | Assessment occasion coded as -1, 0, or 1 |
| `RESP` | Transformed response used in model fitting |

MoCA is generated at times 0 and 1. p-tau217 is generated at times -1, 0, and 1. The generator offers complete data and a calibrated MAR scenario. The numerical generating parameters are aggregate model estimates and do not reproduce individual records.

Generated SAS datasets are written to `data/generated/` and are excluded from Git.

`simulation_tradeoff_summary.csv` contains only aggregated simulation results.
It is created by `code/08_summarize_simulation.sas` and is the input used by
`code/10_create_simulation_tradeoff_figure.R`.
