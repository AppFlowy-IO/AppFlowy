use crate::errors::{ErrorBuilder, ErrorCode, UserError};
use flowy_database::{DBConnection, Database};
use lazy_static::lazy_static;
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use std::{collections::HashMap, sync::RwLock};

lazy_static! {
    static ref DB: RwLock<Option<Database>> = RwLock::new(None);
}

pub(crate) struct UserDB {
    db_dir: String,
}

impl UserDB {
    pub(crate) fn new(db_dir: &str) -> Self {
        Self {
            db_dir: db_dir.to_owned(),
        }
    }

    fn open_user_db(&self, user_id: &str) -> Result<(), UserError> {
        if user_id.is_empty() {
            return Err(ErrorBuilder::new(ErrorCode::UserDatabaseInitFailed)
                .msg("user id is empty")
                .build());
        }

        let dir = format!("{}/{}", self.db_dir, user_id);
        let db = flowy_database::init(&dir).map_err(|e| {
            log::error!("flowy_database::init failed, {:?}", e);
            ErrorBuilder::new(ErrorCode::UserDatabaseInitFailed)
                .error(e)
                .build()
        })?;

        let mut db_map = DB_MAP.write().map_err(|e| {
            ErrorBuilder::new(ErrorCode::UserDatabaseWriteLocked)
                .error(e)
                .build()
        })?;

        db_map.insert(user_id.to_owned(), db);
        Ok(())
    }

    pub(crate) fn close_user_db(&self, user_id: &str) -> Result<(), UserError> {
        let mut db_map = DB_MAP.write().map_err(|e| {
            ErrorBuilder::new(ErrorCode::UserDatabaseWriteLocked)
                .msg(format!("Close user db failed. {:?}", e))
                .build()
        })?;
        set_user_db_init(false, user_id);
        db_map.remove(user_id);
        Ok(())
    }

    pub(crate) fn get_connection(&self, user_id: &str) -> Result<DBConnection, UserError> {
        if !is_user_db_init(user_id) {
            let _ = self.open_user_db(user_id)?;
            set_user_db_init(true, user_id);
        }

        let db_map = DB_MAP.read().map_err(|e| {
            ErrorBuilder::new(ErrorCode::UserDatabaseReadLocked)
                .error(e)
                .build()
        })?;

        match db_map.get(user_id) {
            None => Err(ErrorBuilder::new(ErrorCode::UserDatabaseInitFailed)
                .msg("Get connection failed. The database is not initialization")
                .build()),
            Some(database) => Ok(database.get_connection()?),
        }
    }
}

lazy_static! {
    static ref DB_MAP: RwLock<HashMap<String, Database>> = RwLock::new(HashMap::new());
}

static INIT_FLAG_MAP: Lazy<Mutex<HashMap<String, bool>>> = Lazy::new(|| Mutex::new(HashMap::new()));
fn set_user_db_init(is_init: bool, user_id: &str) {
    let mut flag_map = INIT_FLAG_MAP.lock();
    flag_map.insert(user_id.to_owned(), is_init);
}

fn is_user_db_init(user_id: &str) -> bool {
    match INIT_FLAG_MAP.lock().get(user_id) {
        None => false,
        Some(flag) => flag.clone(),
    }
}

#[cfg(test)]
mod tests {

    #[test]
    fn init_db_test() {
        // init_user_db(".").unwrap();
    }
}
