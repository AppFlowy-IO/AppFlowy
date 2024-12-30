use diesel::{
  dsl::sql, expression::SqlLiteral, query_dsl::LoadQuery, sql_query, sql_types::SingleValue,
  Connection, RunQueryDsl, SqliteConnection,
};

use crate::sqlite_impl::errors::*;

pub trait ConnectionExtension: Connection {
  fn query<'query, ST, T>(&mut self, query: &str) -> Result<T>
  where
    SqlLiteral<ST>: LoadQuery<'query, SqliteConnection, T>,
    ST: SingleValue;

  fn exec(&mut self, query: impl AsRef<str>) -> Result<usize>;
}

impl ConnectionExtension for SqliteConnection {
  fn query<'query, ST, T>(&mut self, query: &str) -> Result<T>
  where
    SqlLiteral<ST>: LoadQuery<'query, SqliteConnection, T>,
    ST: SingleValue,
  {
    Ok(sql::<ST>(query).get_result(self)?)
  }

  fn exec(&mut self, query: impl AsRef<str>) -> Result<usize> {
    Ok(sql_query(query.as_ref()).execute(self)?)
  }
}
