# Research Project

In our project we want to look into how SSD's with Flexible Data Placement(FDP) works, how read and write to it(Having FDP in mind), look into how DuckDB write and reads from disk, and how we can implement support for FDP into DuckDB. 

> [!NOTE]
> **Goal**: We want to propose a plan of implementing support for SSD's using FDP in DuckDB.

# Docs
We will write work documents in the `./docs` directory. Here we will try to document our findings and notes about DuckDB, SSD's wiht FDP, and our preliminary results.

## Progress and Supervision logs
In `docs/supervision` there will be a weekly log of progress and supervision meeting notes.

# Building DuckDB
1. Initialize the submodule by running the following command:

```
git submodule update --init --recursive
```
2. Build DuckDB
```
cd duckdb
GEN=ninja make
```

The DuckDB binary will be located `build/release/duckdb` in the submodule `duckdb`.

# Runnig benchmarks
Navigate to the benchmark folder and run `run_bench.sh`. This starts a tmux session called experiment, in which runs the experiment.
