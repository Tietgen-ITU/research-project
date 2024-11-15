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

### Mapping between BlockManager and positions in files
