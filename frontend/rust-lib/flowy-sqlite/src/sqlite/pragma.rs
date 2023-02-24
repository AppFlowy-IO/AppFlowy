#![allow(clippy::upper_case_acronyms)]
use crate::sqlite::errors::{Error, Result};
use diesel::{
  expression::SqlLiteral,
  query_dsl::load_dsl::LoadQuery,
  sql_types::{Integer, Text},
  SqliteConnection,
};

use crate::sqlite::conn_ext::ConnectionExtension;
use std::{
  convert::{TryFrom, TryInto},
  fmt,
  str::FromStr,
};

pub trait PragmaExtension: ConnectionExtension {
  fn pragma<D: std::fmt::Display>(&self, key: &str, val: D, schema: Option<&str>) -> Result<()> {
    let query = match schema {
      Some(schema) => format!("PRAGMA {}.{} = '{}'", schema, key, val),
      None => format!("PRAGMA {} = '{}'", key, val),
    };
    tracing::trace!("SQLITE {}", query);
    self.exec(&query)?;
    Ok(())
  }

  fn pragma_ret<ST, T, D: std::fmt::Display>(
    &self,
    key: &str,
    val: D,
    schema: Option<&str>,
  ) -> Result<T>
  where
    SqlLiteral<ST>: LoadQuery<SqliteConnection, T>,
  {
    let query = match schema {
      Some(schema) => format!("PRAGMA {}.{} = '{}'", schema, key, val),
      None => format!("PRAGMA {} = '{}'", key, val),
    };
    tracing::trace!("SQLITE {}", query);
    self.query::<ST, T>(&query)
  }

  fn pragma_get<ST, T>(&self, key: &str, schema: Option<&str>) -> Result<T>
  where
    SqlLiteral<ST>: LoadQuery<SqliteConnection, T>,
  {
    let query = match schema {
      Some(schema) => format!("PRAGMA {}.{}", schema, key),
      None => format!("PRAGMA {}", key),
    };
    tracing::trace!("SQLITE {}", query);
    self.query::<ST, T>(&query)
  }

  fn pragma_set_busy_timeout(&self, timeout_ms: i32) -> Result<i32> {
    self.pragma_ret::<Integer, i32, i32>("busy_timeout", timeout_ms, None)
  }

  fn pragma_get_busy_timeout(&self) -> Result<i32> {
    self.pragma_get::<Integer, i32>("busy_timeout", None)
  }

  fn pragma_set_journal_mode(&self, mode: SQLiteJournalMode, schema: Option<&str>) -> Result<i32> {
    self.pragma_ret::<Integer, i32, SQLiteJournalMode>("journal_mode", mode, schema)
  }

  fn pragma_get_journal_mode(&self, schema: Option<&str>) -> Result<SQLiteJournalMode> {
    self
      .pragma_get::<Text, String>("journal_mode", schema)?
      .parse()
  }

  fn pragma_set_synchronous(
    &self,
    synchronous: SQLiteSynchronous,
    schema: Option<&str>,
  ) -> Result<()> {
    self.pragma("synchronous", synchronous as u8, schema)
  }

  fn pragma_get_synchronous(&self, schema: Option<&str>) -> Result<SQLiteSynchronous> {
    self
      .pragma_get::<Integer, i32>("synchronous", schema)?
      .try_into()
  }
}
impl PragmaExtension for SqliteConnection {}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum SQLiteJournalMode {
  DELETE,
  TRUNCATE,
  PERSIST,
  MEMORY,
  WAL,
  OFF,
}

impl fmt::Display for SQLiteJournalMode {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "{}",
      match self {
        Self::DELETE => "DELETE",
        Self::TRUNCATE => "TRUNCATE",
        Self::PERSIST => "PERSIST",
        Self::MEMORY => "MEMORY",
        Self::WAL => "WAL",
        Self::OFF => "OFF",
      }
    )
  }
}

impl FromStr for SQLiteJournalMode {
  type Err = Error;

  fn from_str(s: &str) -> Result<Self> {
    match s.to_uppercase().as_ref() {
      "DELETE" => Ok(Self::DELETE),
      "TRUNCATE" => Ok(Self::TRUNCATE),
      "PERSIST" => Ok(Self::PERSIST),
      "MEMORY" => Ok(Self::MEMORY),
      "WAL" => Ok(Self::WAL),
      "OFF" => Ok(Self::OFF),
      _ => Err(format!("Unknown value {} for JournalMode", s).into()),
    }
  }
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum SQLiteSynchronous {
  EXTRA = 3,
  FULL = 2,
  NORMAL = 1,
  OFF = 0,
}

impl fmt::Display for SQLiteSynchronous {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "{}",
      match self {
        Self::OFF => "OFF",
        Self::NORMAL => "NORMAL",
        Self::FULL => "FULL",
        Self::EXTRA => "EXTRA",
      }
    )
  }
}

impl TryFrom<i32> for SQLiteSynchronous {
  type Error = Error;

  fn try_from(v: i32) -> Result<Self> {
    match v {
      0 => Ok(Self::OFF),
      1 => Ok(Self::NORMAL),
      2 => Ok(Self::FULL),
      3 => Ok(Self::EXTRA),
      _ => Err(format!("Unknown value {} for Synchronous", v).into()),
    }
  }
}

impl FromStr for SQLiteSynchronous {
  type Err = Error;

  fn from_str(s: &str) -> Result<Self> {
    match s.to_uppercase().as_ref() {
      "0" | "OFF" => Ok(Self::OFF),
      "1" | "NORMAL" => Ok(Self::NORMAL),
      "2" | "FULL" => Ok(Self::FULL),
      "3" | "EXTRA" => Ok(Self::EXTRA),
      _ => Err(format!("Unknown value {} for Synchronous", s).into()),
    }
  }
}
