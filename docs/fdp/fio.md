# Overview of workloads, parameters and metrics for micro-benchmarking FDP with FIO
___

## Metrics
___

1. Write Amplication Factor (WA, WAF)
   
   This is one of the main concern on SSDs when considering performance, and it is why FDP was proposed in the first place. It will the foundation of our performance analysis.

2. IOPS (input/output operations per second) (Thruoughput)

    This is often the performance metrics that are advertized by the vendor of the SSDs. It will hopefullt correlate to the WAF - the lower the WAF the higher the IOPS.

3. Latency / bandwith
    
    Latency is the amount of time taken to satisfy a single request (on average), and the bandwith is the amount of operations per second (IOPS) times the block size.

4. Power consumption

    One of the benefits of FPD is reducing the write amplification, which is the main contributor to extra power consumption. All power used that is not related to the media (data) that the host wants to write is considered extra power consumption. It could be interesting in how much power can be saved.

___

## (fio) parameters (consistent across runs)
___

1. `ioengine`

It is specified in the `man` page of fio that to enable FDP, the `ioengine` used for testing must be either `io_uring_cmd` or `xnvme`. In would probably be smart to start out with `io_uring_cmd` in order to align with DuckDB's vision. That is, reducing the amount of libraries needed for a feature, or at least not introducing unnecessary libraries.

2. `direct`

It tells FIO to either enable or disable caching, forcing commands to be sent to the drive directly. Can be either `0` or `1`.

3. `loops`

It tells FIO to run the specific "job" a certain number of times, essentially repeat the workload a number of times. This can be any `N`, but of course must be aligned accordingly in the total running time.

4. `group-reporting`

Can be used with `numjobs` in order to report a mean across a number of threads. Just a single result rather than per thread result. Can look into creating reporting groups with the `new_group` flag.

5. `cpus_allowed`

Specifies which cores on a CPU are allowed to be used in the job. This will be a list of core IDs of the cores that will be used.

6. `fdp` - levels: 0, 1

Enables or disables FDP write command. Essentially, this assumes that you have a FDP configuration already.

7. `fpd_pli_select`

Specifies to FIO how to choose the next placement handle identifier, thtat is which RUH (reclaim unit handler) should be used next. This can be random or round robin.

8. `fpd_pli`

Specifies which placement identifiers that are allowed to be used in a job (indirectly choosing which RUH (reclaim unit handles) that will be used). Can isolate specific ids for specific jobs.

9. `filename`

Specifies the file that will be used in the job. If nothing is specified FIO will make one, but if the file should be shared across threads, then you should create one yourself. (Don't know how this work specifically) 

10. `cmd_type`

Specifies the unring passthrough command, the default is nvme (which is what we are going to use), but good to specify.

## possible Parameters 
___

1. `numjobs` - levels: $2^0, 2^1, ..., 2^4$

The amount of clones spawned to a specific job, each clone will spawn an independent thread/process. Hence, this is the number of threads used.

2. `iodepth` - levels: $2^0, 2^1, ..., 2^7$

The amount of I/O requests that can be queued? FIO list this as the number of I/O units to keep in flight against the file. It is possible that the number specified in the flag cannot be met due other circumstances, i.e. OS restrictions.

3. `bs` - levels: 4k, ?

The block size (in bytes) used for I/O units. Varying size might give different results for FDP?

4. `rw` - levels: `randread`, `randwrite`, `write`

This is specifying what type of workload that FIO should perform. The FDP specification specifies that it only affects the performance of writes. It would be smart to test this, hence testing both random reads and writes. Furthermore, they mention in the videos ([this](https://youtu.be/BENgm5a17ws?feature=shared&t=73)), that the smaller write amplication factor that closer you will be to the performance of a sequential write. Guessing that it would be possible to try to compare this in correlation to the WAF by performance testing sequential writes also.

5. `size` - levels: 30%, 50%, 70%, 90% etc. or 100GB, 500GB (depeding on size)

Specifies thesize of the workload. We need to figure out a way to fairly compare the SSD with FDP disabled and enabled. An example would be that you have an FDP configuration with two RG (reclaim groups) with two RUH (reclaim unit handlers) each with 100GB - this would need to be tested against an SSD (a partition) of 200 GB. Then you would probably test against certain capacity thresholds, i.e. using the percentage of the capacity as a level.

 






    
