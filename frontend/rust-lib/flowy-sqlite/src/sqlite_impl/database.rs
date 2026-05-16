use std::sync::Arc;

use r2d2::PooledConnection;

use crate::sqlite_impl::{
  errors::*,
  pool::{ConnectionManager, ConnectionPool, PoolConfig},
};

#[derive(Clone)]
pub struct Database {
  uri: String,
  pool: Arc<ConnectionPool>,
}

pub type DBConnection = PooledConnection<ConnectionManager>;

impl Database {
  pub fn new(dir: &str, name: &str, pool_config: PoolConfig) -> Result<Self> {
    let uri = db_file_uri(dir, name);

    if !std::path::PathBuf::from(dir).exists() {
      tracing::error!("Create database failed. {} not exists", &dir);
    }

    let pool = ConnectionPool::new(pool_config, &uri)?;
    Ok(Self {
      uri,
      pool: Arc::new(pool),
    })
  }

  pub fn get_uri(&self) -> &str {
    &self.uri
  }

  pub fn get_connection(&self) -> Result<DBConnection> {
    let conn = self.pool.get()?;
    Ok(conn)
  }

  pub fn get_pool(&self) -> Arc<ConnectionPool> {
    self.pool.clone()
  }
}

pub fn db_file_uri(dir: &str, name: &str) -> String {
  use std::path::MAIN_SEPARATOR;

  let mut uri = dir.to_owned();
  if !uri.ends_with(MAIN_SEPARATOR) {
    uri.push(MAIN_SEPARATOR);
  }
  uri.push_str(name);
  uri
}
