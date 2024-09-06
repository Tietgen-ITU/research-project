# DuckDB I/O
This document aims to describe how DuckDB manages reads and writes to disk. There may be som mechanisms that goes to main memory before, and then "flushes" it to disk when needed. Everything will be covered in this document and files will be referenced including adding figures where needed.

## Possible articles, papers, or blog posts to look at
- [DuckDB Memory Management](https://duckdb.org/2024/07/09/memory-management.html)
