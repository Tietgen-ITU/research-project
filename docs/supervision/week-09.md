# Supervision

@emiloh and @arnenator met pinar for supervision this week. The supervision was mostly about claryfying questions that we had, and some we need to ask Vivek about

1. Why is not possible to have a namespace with all placement handlers? It seems that the maximum placement handlers within a single namespace is 7.
2. Do all placement handlers have their own ranges of LBA's, or are the ranges shared between them? Is this something we can query per placement handler? That is, what is the next LBA that can be written to by a placement handler?
3. Along with 2., do the configuration of the device have anything to say here? Is there a difference if all placement handlers / RUH are initially isolated vs persistently isolated ? 
4. Can you dynamically change the namespace? Will the data within the namespace be deleted then? 

# Work

@emiloh have continued on the benchmark setup, and the structure is pretty much done now. Furthermore, both fio and xNVMe have been installed on the server, which lead to several problems. Below each problem is described, and the solution if @emiloh found a solution:

1. fio could not find `libxnvme.so.0`

fio could not find the dynamically linked library `libxnvme.so.0`, however this have been resolved by exposing the path to that library. Through the export command, we can include the full path to the library (`/usr/local/lib64`) into `LD_LIBRARY_PATH`.

2. Running fio with `ioengine=io_uring_cmd`

When running the benchmark with `ioengine=io_uring_cmd`, we get an error code of `-38`. This error code is `ENOSYS` (a syscall error code), which means that the function is not implemented, simply that the backend cannot be found. Essentially, we need to find a way for fio to find `io_uring_cmd`. A solution for this have not been found yet, but by using `ioengine=xnvme` and `xnvme_async=io_uring_cmd` this is problem does not persist.

3. Running fio with `ioengine=io_uring`

When running the benchmark with `ioengine=io_uring`, we experience an `io_u` error. This is becuase we tried to run the benchmark with the device `/dev/ng1n1`, but this is incorrect, instead `/dev/nvme1n1` is correct device to use (reference [link](https://github.com/vincentkfu/fio-blog/wiki/xNVMe-ioengine-Part-1)).

4. Runnnig fio with `ioengine=xnvme` and `xnvme_async=io_uring_cmd`

This will most likely work, however this results in an error becuase of the file/filesystem. Essentially, the error states that `O_DIRECT` is not allowed on the file (device) `/dev/ng1n1`. From runnign the command `df -hT`, we see that the `/dev` is mounted with the filesystem `devtmpfs`, which does not allow for `O_DIRECT`. Pinar said this is normal, given that different device will most likely have different filesystems. A thing to tryout now would be to mount the device, which might allow us to use `O_DIRECT`.  Two commands that will be very useful in this are `fdisk -l`, which shows the current partitions you have (and which filesystem they have) and `mount`, a command for mounting devices (to see the possible flags and usage, look at the man page).


@arnenator have looked into DuckDB and how they interact with the disk, what kind of filesystem they use etc.

