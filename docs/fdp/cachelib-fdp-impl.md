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
- **MemoryDevice** - Manages reads and writes to main memory, it is described in the documentation to be a test class(So it is not relevant) 

> [!NOTE]
> All the IO passthru code is implemented in their Folly library. In there they add a reference to the [Liburing](https://github.com/axboe/liburing/tree/master) library which is implemented by Jens Axboe.

## 2 - A deeper look

### `FDPNVMe.cpp`

This section describes what the `FDPNVMe.cpp` file introduces and provides. It will go through some of the code where it specifically handles read and write. 

`FDPNVMe.cpp` implements the `FdpNvme` class. It is created by providing the file path to the char device file and the namespace file that it operates on. It is important to note that writing to a specific file is not the case here. We write directly to disk. The file that is being written to, is the device file. For that reason facebook has created their own logically constructed file abstraction, that can be used to represent the char device file as a normal file that you write to. 

When creating the `FdpNvme` instance, it also ask the device for information. The information could be e.g. the number of Resource Unit Handles(RUHs). This communication is all handled in the `nvmeIOMgmtRecv()` function, and uses the `ioctl` system call to fetch this information(This call is documented in the NVMe spec, and this is also referenced in the code). 

> [!IMPORTANT] 
> TODO: We need to look into how to specify what to write and where. How does this make sense in a NVME SSD. How does CacheLib write the objects directly to the SSD? How do they manage where to place them and where to read them?

This class has two important methods, namely `prepReadUringCmdSqe()` and `prepWriteUringCmdSqe()`. These two commands is an essential part to prepare the entry for the `io_uring`. Both of these methods call a private method called `prepFdpUringCmdSqe()`. 

> [!NOTE]
> `sq` stands for *submission queue* and `sqe` stands for *submission queue entry*. It is also worth mentioning that there is a *completion queue*(cq) and it is called *completion queue event*(cqe) when it is an entry in the cq.

`prepFdpUringCmdSqe()` essentially prepares the entry by populating the entry with FDP specific directives. As can be seen the normal `io_uring_cmd` struct defines a union field specifically to add an arbitrary struct defining the command specifically to the device. In this case the nvme spec has this struct defined, and CacheLib has called it `nvme_uring_cmd`. 

### `Device.cpp`

Is an abstract class representation of the actual device. As seen in the code there are two classes that inherits the Device class and implements the `writeimpl` and `readimpl` functions. 

The classes that inherits from `Device` is:
- `FileDevice`
- `MemoryDevice` (We will not cover this in detail as it is mostly used for mocking purposes and does to use any of the things that we look in to)

`FileDevice` specifically represents a device by interfacing directly with the device char file. It is created by calling the `createDevice()` function inside the `Navysetup.cpp`. Here it decides whether it should be a `FileDevice` or an `MemoryDevice`. The `FileDevice` is being created by calling the `createFileDevice()` which calls the `createDirectIoFileDevice()`(The last two functions is implemented inside the `Device.cpp`). 

**`createFileDevice()`**

This function is special in the way that it fetches file descriptors of the files defined by the config. Essentially, the function has `Vector<string> filenames` as a parameter. These file names are paths to the char device. In order, to call the `createDirectIoFileDevice()` function it needs to provide a vector of file descriptors(fd) and the vector of file paths. 

So essentially it gets the file descriptor of the char device(s) and pass that vector together with the filepaths already provided as a parameter to the `createDirectIoFileDevice()`.

**`createDirectIoFileDevice()`**

In this function it uses that `filepaths` and creates the `FdpNvme` instances(It only supports one instance). Then it parses all the other parameters to the `FileDevice` constructor.

### Write data to NVMe

Writing directly to device means that the host has to handle some management of where to place that data. That management is handled by the `Device` class. However, the IO requests is abstracted into a class called `IOContext`. 

<!-- TODO: write more about the IO context and IOReq -->

<!-- TODO: Look into the RegionManager:542. It does some translation from an address to an offset -->
