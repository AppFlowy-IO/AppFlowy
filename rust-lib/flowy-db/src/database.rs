use crate::errors::FlowyDBError;
use diesel_migrations::*;
use flowy_infra::sqlite::*;
use std::path::Path;

embed_migrations!("../flowy-db/migrations/");
pub const DB_NAME: &str = "flowy-database.db";

pub fn init(storage_path: &str) -> Result<DataBase, FlowyDBError> {
    if !Path::new(storage_path).exists() {
        std::fs::create_dir_all(storage_path)?;
    }

    let pool_config = PoolConfig::default();
    let database = DataBase::new(storage_path, DB_NAME, pool_config)?;
    Ok(database)
}
