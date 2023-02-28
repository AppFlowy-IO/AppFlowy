use flowy_error::FlowyError;
use flowy_sqlite::{ConnectionPool, DBConnection};
use std::sync::Arc;

pub mod block_index;
pub mod database_ref;
pub mod kv;
pub mod migration;
pub mod rev_sqlite;

pub trait DatabaseDBConnection: Send + Sync {
  fn get_db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;

  fn get_db_connection(&self) -> Result<DBConnection, FlowyError> {
    let pool = self.get_db_pool()?;
    let conn = pool.get().map_err(|e| FlowyError::internal().context(e))?;
    Ok(conn)
  }
}
