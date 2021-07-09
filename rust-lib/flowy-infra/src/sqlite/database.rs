use crate::{
    errors::*,
    sqlite::pool::{ConnectionManager, ConnectionPool, PoolConfig},
};
use r2d2::PooledConnection;

pub struct DataBase {
    uri: String,
    pool: ConnectionPool,
}

impl DataBase {
    pub fn new(dir: &str, name: &str, pool_config: PoolConfig) -> Result<Self> {
        let uri = db_file_uri(dir, name);
        let pool = ConnectionPool::new(pool_config, &uri)?;
        Ok(Self { uri, pool })
    }

    pub fn get_uri(&self) -> &str { &self.uri }

    pub fn get_conn(&self) -> Result<PooledConnection<ConnectionManager>> {
        let conn = self.pool.get()?;
        Ok(conn)
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
