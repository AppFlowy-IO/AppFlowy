use flowy_database::{ConnectionPool, DBConnection};
use flowy_error::FlowyError;
use std::sync::Arc;

pub mod block_index;
pub mod kv;
pub mod migration;

pub trait GridDatabase: Send + Sync {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;

    fn db_connection(&self) -> Result<DBConnection, FlowyError> {
        let pool = self.db_pool()?;
        let conn = pool.get().map_err(|e| FlowyError::internal().context(e))?;
        Ok(conn)
    }
}
