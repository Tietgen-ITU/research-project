# CahceLib implemenation of FDP suppoert in NVMe

This document tries to describe how Meta has implemented FDP support for NVMe SSDs. In particular we are going to look at the specific commit that introduced it to the codebase initialy(See [here](https://github.com/facebook/CacheLib/commit/009e89ba2b49b1fbbc48d03c3f81046de28bd6ed)).

> [!NOTE]
> The commit message describes that the WAF is creatly reduced. This corresponds nicely to the FDP whitepaper that Pinar has provided us. This could be an interesting thing to see if we can reproduce the same results.

<!--TODO: Write what the reader is going to see in the different sections -->

## 1 - High Level Overview

This section will at a high level introduce what is being added to the project.  

## 2 - A deeper look into `FDPNVMe.cpp`

This section describes what the `FDPNVMe.cpp` file introduces and provides. It will go through some of the code where it specifically handles read and write.
