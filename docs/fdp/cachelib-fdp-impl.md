# CahceLib implementation of FDP support in NVMe

This document tries to describe how Meta has implemented FDP support for NVMe SSDs. In particular we are going to look at the specific commit that introduced it to the codebase initially(See [here](https://github.com/facebook/CacheLib/commit/009e89ba2b49b1fbbc48d03c3f81046de28bd6ed)).

> [!NOTE]
> The commit message describes that the WAF is greatly reduced. This corresponds nicely to the FDP white-paper that Pinar has provided us. This could be an interesting thing to see if we can reproduce the same results.

<!--TODO: Write what the reader is going to see in the different sections -->

## 1 - High Level Overview

This section will at a high level introduce what is being added to the project.  

CacheLib handles its communication with the FDP supported NVMe through the class called `FdpNvme` which is located in the file `navy/common/FdpNvme.hpp`. The actual implementation is in the `navy/common/FdpNvme.cpp` file.

> From what we understand it creates a file descriptor (fd) via its constructor to handle the communication with the SSD. The communication between the OS and the SSD happens via `IO_URING`. The high level details of this class is that it helps with the communication to the NVMe device by creating commands which it writes to the allocated fd which the `IO_URING` picks up and then performs the action.

The FDP implementation is then used in the `Device.cpp` and `Device.hpp`. What they essentially do is to provide a common interface for memory devices. Here they have two concrete implementations:

- **FileDevice** - Manages reads and writes to disk (we assume)
- **MemoryDevice** - Manages reads and writes to main memory 

## 2 - A deeper look into `FDPNVMe.cpp`

This section describes what the `FDPNVMe.cpp` file introduces and provides. It will go through some of the code where it specifically handles read and write.
