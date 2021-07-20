use crate::errors::*;
use diesel::{
    dsl::sql,
    expression::SqlLiteral,
    query_dsl::LoadQuery,
    Connection,
    RunQueryDsl,
    SqliteConnection,
};

pub trait ConnectionExtension: Connection {
    fn query<ST, T>(&self, query: &str) -> Result<T>
    where
        SqlLiteral<ST>: LoadQuery<SqliteConnection, T>;

    fn exec(&self, query: impl AsRef<str>) -> Result<usize>;
}

impl ConnectionExtension for SqliteConnection {
    fn query<ST, T>(&self, query: &str) -> Result<T>
    where
        SqlLiteral<ST>: LoadQuery<SqliteConnection, T>,
    {
        Ok(sql::<ST>(query).get_result(self)?)
    }

    fn exec(&self, query: impl AsRef<str>) -> Result<usize> {
        Ok(SqliteConnection::execute(self, query.as_ref())?)
    }
}
