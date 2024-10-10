#include "../../duckdb/src/include/duckdb.hpp"

int main()
{
    duckdb::DuckDB db;
    duckdb::Connection con(db);
    duckdb::Appender appender(con, "test");
    appender.BeginRow();
    appender.Append<int32_t>(42);
    appender.Append("hello");
    appender.EndRow();
    appender.Flush();
    auto result = con.Query("SELECT * FROM test");
    return 0;
}