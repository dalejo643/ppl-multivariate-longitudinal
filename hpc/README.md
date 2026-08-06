# HPC execution

The final design uses 500 replications for each sample size. `--array=1-500%20` assigns one replication to each array task and permits at most 20 concurrent tasks. The time limit therefore applies to one complete simulation replication, not to a block of 20 replications.

Example submission:

```bash
sbatch --export=ALL,REPO_ROOT=/path/to/repository,SIM_OUTPUT=/path/to/results/N5000,SIM_N=5000 hpc/simulation_array.batch
```

Run separate arrays for N=2500, 5000, and 10000. Resource requests are templates and should be adjusted using scheduler accounting from validation runs. The statistical models within a replication are executed sequentially.
