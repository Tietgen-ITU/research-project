# Buffer Manager

This describes the `BufferManager.cpp` and `BufferManager.hpp` files in DuckDB. The BufferManager is responsible for caching as many items in main memory as possible. In the case where the cached items becomes larger than the space available in main memory it will spill to disk in a temporary file in the `/tmp` directory.

We will go into more details about this and describe different parts of the `BufferManager` class. In particular, we will focus on the method `WriteTemporaryBuffer()`.

## Overview

Like with the file system which had the abstract class `FileSystem`, `buffer_manager.hpp` and `buffer_manager.cpp` contains the abstract class `BufferManager`.

One of the class that implements `BufferManager` is `StandardBufferManager`

<!-- TODO: We need to look at the buffer pool in duckdb -->

## Buffer Manager

> [!IMPORTANT]
> It is possible to inject a completely different `BufferManager` by setting the `DBConfig::buffer_manager` field(Just like with the `FileSystem`)

> Note the class `BufferManager` is in it self not that interesting. It serves more like an interface. The interesting parts are in the implementation i.e. `StandardBufferManager`. From now on when we say buffer manager we refer to `StandardBuffermanager` unless it is explicitly stated as `BufferManager`.

When we look at the `BufferManager` we have two methods that we are specifically interested in:

1. `StandardBufferManager::WriteTemporaryBuffer()`
2. `StandardBufferManager::ReadTemporaryBuffer()`

In order for the buffer manager to control file management it relies on the `TemporaryDirectoryHandle`.

> `TemporaryDirectoryHandle` is responsible for creating the temporary directory if not already created and create a `TemporaryFileManager` for the path needed that handles interactions with files in that particular directory.

The `WriteTemporaryBuffer` contains a parameter `tag` which is of type `MemoryTag`. `MemoryTag` is an enum which defines what kind of data is being written to the buffer:

```c++
enum class MemoryTag : uint8_t {
	BASE_TABLE = 0,
	HASH_TABLE = 1,
	PARQUET_READER = 2,
	CSV_READER = 3,
	ORDER_BY = 4,
	ART_INDEX = 5,
	COLUMN_DATA = 6,
	METADATA = 7,
	OVERFLOW_STRINGS = 8,
	IN_MEMORY_TABLE = 9,
	ALLOCATOR = 10,
	EXTENSION = 11
};
```

## Temporary File Manager

> **Temp file Stats**:
>
> Temporary file block allocation size: 262144 bytes (256 KB)

Where the `TemporaryDirectoryManager` is responsible for handling creation of the directory and creating the `TemporaryFileManager`, the `TemporaryFileManager` is responsible for creating and deleting `TemporaryFileHandlers`. In fact, the `TemporaryFileManager` has a field called `files` which is a type of `map<idx_t, unique_ptr<TemporaryFileHandler>>`.

**Where are the `TemporaryFileHandler`s being created?**

All `TemporaryFileHandler`s are being created in the `TemporaryFileManager::WriteTemporaryBuffer()` at line 300.  

`TemporaryFileHandler`s are only being created when there is no existing `TemporaryFileHandler` available to use in `TemporaryFileManager`. The constructor of the `TemporaryFileHandler` sets the `max_allowed_index` by `(1 << temp_file_count) * MAX_ALLOWED_INDEX_BASE` and set the file path to the configured temporary storage directory concatenated with the `new_file_index` from the `index_manager` and a file extension `.tmp` (see line 97:101 in `temporary_file_manager.cpp`).

The strange quirk is that for each new file that the `TemporaryFileManager` decides to create, the larger the amount of indexes it is allowed to keep(This could be seen in the constructor setting the `max_allowed_index`).

However, if there is an existing file, when do we know that we should create a new one? To answer the question we need to start look at line 291-292 in `temporary_file_manager.cpp`. Here we call the `TemporaryFileHandler::TryGetBlockIndex()`. Taking a deeper look into the `TemporaryFileHandler::TryGetBlockIndex()`, it checks that the next index that could be fetched from the `IndexManager` instance inside the `TemporaryFileHandler` does not exceed or is equal to the `max_allowed_index` and that there are free blocks left. In that case it returns a standard `TemporaryFileIndex`. `TemporaryFileIndex` contains a method `IsValid()` which in the case where nothing is provided in the constructor, would return false. 

In the case where the `TemporaryFileManager` goes through all the available `TemporaryFileHandler`s and none of the return a valid `TemporaryFileIndex` then it creates a new instance of `TemporaryFileHandler`.

> @emiloh thinks that the reason why the files should be able to exponentially handle more indexes is based on the same mechanism as an ArrayList in java. However, this brings the question why not keep it in one file? And this could be due to the amount of data that we are going to occupy on the disk. The data is not being deleted until the whole file is deleted. 

### Mapping between BlockManager and positions in files

The `BlockManager` is responsible for managing the data in main memory. It does so by organizing the data with what is being called `Block`s(essentially a FileBuffer). A `Block` has two states, namely `LOADED` and `UNLOADED` representing whether the block is loaded with main memory data or if the `Block` has been `UNLOADED` to disk.

In `DuckDB` they have a `BlockManager`. But in the case where the database has a file where the data is being kept it actually has extended the `BlockManager` with another concrete implementation called the `SingleFileBlockManager`(You can see the creation of it in the `StorageManager` line 190-193). 

If `DuckDB` is running in an `InMemory` configuration, it uses the concrete implementation of the `BlockManager`, called `InMemoryBlockManager`. 

However, the `StandardBufferManager` is actually using the `InMemoryBlockManager`. For that reason we are going to looke 



#### `InMemoryBlockManager` vs. `SingleFileBlockManager`?

The concepts are the same. The manages blocks in different domains. `InMemoryBlockManager` manages blocks in main memory, this is the one used to handle the main memory blocks in the `StandardBufferManager`. The `SingleFileBlockManager` manages blocks in a single file.

## Flow of spilling to disk

Before going through the flow of spilling to disk, we need to have the following two questions in mind:

- How do we manage what is being spilled to disk?
- How do we use the data spilled to disk and get it back to main memory?
- When do we spill to disk?

The journey of spilling to disk starts at the `StandardBufferManager::WriteTemporaryBuffer()`. We have already described previously how the TemporaryFileManager and handlers work and that the `WriteTemporaryBuffer()` function uses that to first write the header but then use the `FileBuffer`, which in reality is an instance of type `Block`, to *unload* the buffer to the temporary file. So the reason why we start at the `WriteTemporaryBuffer()` is because we want to trace back where it is being called and why?. 

The function is first being called by the `BlockHandle::UnloadAndTakeBlock()`. 

```mermaid
---
title: Paths to `StandardBufferManager::WriteTemporaryBuffer()`
---
flowchart TD
	StandardBufferManager::BufferAllocatorAllocate --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::BufferAllocatorAllocate --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::ReserveMemory --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::Pin --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::ReadBatch --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::ReAllocate --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::RegisterMemory --> StandardBufferManager::EvictBlocksOrThrow
	StandardBufferManager::RegisterSmallMemory --> StandardBufferManager::EvictBlocksOrThrow
	BufferPool::SetLimit --> BufferPool::EvictBlocks
	StandardBufferManager::EvictBlocksOrThrow --> BufferPool::EvictBlocks 
	BufferPool::EvictBlocks --> BufferPool::EvictBlocksInternal
	BufferPool::EvictBlocksInternal --> BlockHandle::Unload
	StandardBufferManager::Unpin --> BlockHandle::Unload
	BufferPool::PurgeAgedBlocksInternal --> BlockHandle::Unload
	BufferPool::EvictBlocksInternal --> BlockHandle::UnloadAndTakeBlock
	BlockHandle::Unload --> BlockHandle::UnloadAndTakeBlock
    BlockHandle::UnloadAndTakeBlock --> StandardBufferManager::WriteTemporaryBuffer
```

The tree just keeps growing. But what can be shown of the above figure is that a lot of the functions are calling each other. 

> [!IMPORTANT]
> **TODO:** The`StandardBufferManager` contains its own BlockManager, called the `temporary_block_manager` which seems to be the data that the buffer manager manages in memory and then suddenly pushes to the temporary file. Look further into the functions that uses the `temporary_block_manager` go from there.