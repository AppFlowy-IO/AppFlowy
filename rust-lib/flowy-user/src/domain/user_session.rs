use crate::{domain::user_db::UserDB, errors::UserError};
use flowy_sqlite::DBConnection;
use lazy_static::lazy_static;
use std::sync::RwLock;

lazy_static! {
    pub static ref CURRENT_USER_ID: RwLock<Option<String>> = RwLock::new(None);
}
fn get_current_user_id() -> Result<Option<String>, UserError> {
    match CURRENT_USER_ID.read() {
        Ok(read_guard) => Ok((*read_guard).clone()),
        Err(e) => {
            log::error!("Get current user id failed: {:?}", e);
            Err(e.into())
        },
    }
}

pub struct UserSessionConfig {
    root_dir: String,
}

impl UserSessionConfig {
    pub fn new(root_dir: &str) -> Self {
        Self {
            root_dir: root_dir.to_owned(),
        }
    }
}

pub struct UserSession {
    db: UserDB,
    config: UserSessionConfig,
}

impl UserSession {
    pub fn new(config: UserSessionConfig) -> Self {
        let db = UserDB::new(&config.root_dir);
        Self { db, config }
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        match get_current_user_id()? {
            None => Err(UserError::UserNotLogin),
            Some(user_id) => self.db.get_connection(&user_id),
        }
    }
}
