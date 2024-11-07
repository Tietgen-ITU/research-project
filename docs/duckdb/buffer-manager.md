# Buffer Manager

This describes the `BufferManager.cpp` and `BufferManager.hpp` files in DuckDB. The BufferManager is responsible for caching as many items in main memory as possible. In the case where the cached items becomes larger than the space available in main memory it will spill to disk in a temporary file in the `/tmp` directory.

We will go into more details about this and describe different parts of the `BufferManager` class. In particular, we will focus on the method `WriteTemporaryBuffer()`.

## Overview

Like with the file system which had the abstract class `FileSystem`, `buffer_manager.hpp` and `buffer_manager.cpp` contains the abstract class `BufferManager`.

One of the class that implements `BufferManager` is `StandardBufferManager`

<!-- TODO: We need to look at the buffer pool in duckdb -->

## Buffer Manager

> [!IMPORTANT]
> It is possible to inject a completly different `BufferManager` by setting the `DBConfig::buffer_manager` field(Just like with the `FileSystem`)

> Note the class `BufferManager` is in it self not that interesting. It serves more like an interface. The interesting parts are in the implementation i.e. `StandardBufferManager`. From now on when we say buffer manager we refer to `StandardBuffermanager` unless it is explicitly stated as `BufferManager`.

When we look at the `BufferManager` we have two methods that we are specifically interested in:

1. `StandardBufferManager::WriteTemporaryFile()`
2. `StandardBufferManager::ReadTemporaryFile()`

In order for the buffer manager to control file management it relies on the `TemporaryDirectoryHandle`.

> `TemporaryDirectoryHandle` is responsible for creating the temporary directory if not already created and create a `TemporaryFileManager` for the path needed that handles interactions with files in that particular directory.

## Temporary File Manager

