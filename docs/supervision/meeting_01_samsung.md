- Ask if you can have a namespace with fdp and without on the same device.
    - Disable FDP on the device to compare against
    - Delete namespace, disable fdp, create a new namespace 


- Ask why we cannot create two namespace with fdp
    - Second namespace can only have one RUH
    - Controller does funky things with multiple namespaces - garbage collection might have different behavior
    - Namespaces does not give you logical isolation - contoller does not isolate, but shared storage
    - Dont use namespace for isolation, but RUHs are very good for isolation
    - RUH are initially isolated, over time might have interference
    - The more parallel write to RUH will probably lead to more garbge collection


- xNvme does this make sense instead in this project
- What dependencies does xNvme have? DuckDB wants lightweight things so liburing is might a better approach
    - A lot of things can be disabled in xNvme - compile time difference
    - Only neeed the headers that you will need
    - start with xNvme
    - proof of concept
    - Leanstore - more complicated, design space is bigger
    - multiplexer
    - xNvme integration into full-fledged database systems
    - Try xNvme first and then switch if it did not work

- How do you talk without file system ?
    - file descriptor - see them as IDs
    - Directly talk to blocks -> map in bufferpool to LBA's


- Have in mind backwards compatibility when integrating into DuckDB
- [QEMU](https://qemu-project.gitlab.io/qemu/system/devices/nvme.html#flexible-data-placement) is nice to have and very well updated, only API compatibility
- FEMU - fdp specific emulator, can be used if we hit a limit on a device and we want to test hypotheses - what if i had another device, does this hold for all devices? 

- Acrhitecture can change - latency, throughput etc. can be improved
- The structs for liburing will need to be created ourselves - there is no open source

- Is there a reset command for both the configuration and the ssd itself (data) - there was one in the paper from this week `blk-something`
    - dsm deallocate
    - Which range of LBA to deallocate


- The most amount of control have multiple namespaces
    - Event logs - how much of the RU are populated
    - Seggration - what amount of 

- READ THE NVME SPEC, QEMU
    - Look at base specification and then you can read the command-set sepcification (flexixble data placement)
    - Wordy, but there is a lot of inforamation


- Experimentaiton
    - Latency - precondition ssd
    - SSD should be empty, this gives reproducability 
    - Blog post about FIO at samsung
    - Samsung use default FIO - atleast for their own purposes 
    - Just fill the device - this can be done very fast
    -


# Report
________________

- Add discussion about xNvme into report
- Add #ifdef in extension duckdb - need to touch the core of DuckDB

- Deliverables:
    - Describe FDP
    - FDP benchmark
    - Plan for benchamrk and implementaiton 
    -

- Add something to apache wayang

