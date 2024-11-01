# Buffer Manager

This describes the `BufferManager.cpp` and `BufferManager.hpp` files in DuckDB. The BufferManager is responsible for caching as many items in main memory as possible. In the case where the cached items becomes larger than the space available in main memory it will spill to disk in a temporary file in the `/tmp` directory.

We will go into more details about this and describe different parts of the `BufferManager` class. In particular, we will focus on the method `WriteTemporary()`