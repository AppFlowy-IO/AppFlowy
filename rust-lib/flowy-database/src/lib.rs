mod errors;
mod schema;

#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_derives;
#[macro_use]
extern crate diesel_migrations;

pub use errors::*;
pub use flowy_sqlite::{DBConnection, DataBase};

use diesel_migrations::*;
use flowy_sqlite::PoolConfig;
use std::path::Path;

embed_migrations!("../flowy-database/migrations/");
pub const DB_NAME: &str = "flowy-database.db";

pub fn init(storage_path: &str) -> Result<DataBase, DataBaseError> {
    if !Path::new(storage_path).exists() {
        std::fs::create_dir_all(storage_path)?;
    }

    let pool_config = PoolConfig::default();
    let database = DataBase::new(storage_path, DB_NAME, pool_config)?;
    Ok(database)
}
