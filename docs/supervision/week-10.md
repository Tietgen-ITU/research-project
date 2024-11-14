# Supervision
___

# Work
___

@emiloh have been in contact with Samsungs Memory Research Center (SMRC) to resolve issues regarding the sevrer as vivek suggested. They have been very responsive during normal workdays, so this is very good to know for the future. There was two issues with the server:

1. SGX was disabled/enabled which meant that the server could not boot. This was fixed. Pinar said that this does not have anything to do with our project.

2. The SSH-agent was not workign probably, and was refusing connections. This have also been resolved. So there is access to the server again

@emiloh have also conducted the first set of experiments. By consulting Karl, we got to know that the flag `--direct` should be disabled. This is apperently only used for block-devices, and given that we bypass the block level completely by having a generic char device, this needs to be omitted. The results are on the server under the branch `feature/fio-setup`. I have created to plots just to showcase (ignore the title on them). All of the benchmarks, non-fdp and fdp, have been run with ioengine = `io_uring_cmd`:

1. This graph have number of `threads/iodepth` on the x axis. Note, here one is kept fixed as 1, so for all diffrent values of threads the `iodepth = 1` and vice versa. The y acis is average IOPS achived on 5 runs.

![image](https://github.com/user-attachments/assets/58efbbef-2c0a-40d9-974d-255c3633c11a)


2. This graphs have the `iodepth` on the x axis, and the `thread` count fixed at 32 threads. The y axis, again, is the average IOPS achieved on 5 runs.

![image](https://github.com/user-attachments/assets/8ec8a28f-d9d6-48be-9726-777f81a0c1d7)


@emiloh have comments on future improvements/issues:

1. The branch `feature/fio-setup` on the server (local) is one commit ahead of origin. We need to find a way to get these commits out, either by adding an SSH-key to the server or some other alternative. It is not a problem for now, we just need to be wary such that we dont lose any progress.

2. The benchmarking script has incorrect use of arrays (levels array for each parameter). They are comma seperated, but in bash they should just be space seperated. This causes issues with the plotting tool that have been made. It is an easy fix tho.

3. The graphs are quite underwhelming. In almost every case FDP performs the same or worse than NON-FDP. It might be an issue that fpd is not probably enabled or disabled. This might very well be an issue with the script, if not, quite sad. But we need to look into it, which starts with double chekcing the setup part in the benchmarking script.

4. The FIO engine cannot find our xNVMe backend, which means that we cannot run the benchmarks with xNVMe. There is probably some linking, path etc. that is not probably set. Again, we have to look into this, but @emiloh did not look much into this.

5. We have to find out how to measure WAF. The easiest way is probably to do as `devops-cachelib` (github) does it. They use a python script that opens a subprocess that will poll the events on the device with a certain time-interval.

6. We need to figure out what graphs would be interesting to present in our research paper. This way, we can extend the plotting and enusre that we have results to talk about in the paper.
