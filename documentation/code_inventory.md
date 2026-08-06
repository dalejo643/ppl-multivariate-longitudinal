# Code inventory

| Module | Public status | Remaining work |
|---|---|---|
| Synthetic-data generator | Prepared | Validate in SAS 9.4M7 |
| Full-data ML/REML model | Prepared | Validate ML and REML outputs in SAS 9.4M7 |
| Partitioned model macro | Prepared | Validate output dimensions and convergence in SAS 9.4M7 |
| PPL combination macro | Pending migration | Repair encoding and document ASYCOV ordering |
| Random-effects correlations | Pending migration | Isolate delta-method module |
| CCA | Prepared | Validate covariance reconstruction and coefficients in SAS 9.4M7 |
| Participant bootstrap | Prepared | Validate with 20 replicates before the full run |
| Simulation batch and summary | Prepared | Validate small batch and final output schema |
| Diagnostic figures | Pending migration | Replace paths and define required input tables |

Original HUNT import and data-management scripts remain internal because they contain restricted source-variable mappings and local data locations. The supplement will document the construction of the analysis variables.
