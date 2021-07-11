use crate::errors::UserError;
use flowy_database::{DBConnection, Database};
use lazy_static::lazy_static;
use std::{
    cell::RefCell,
    sync::{
        atomic::{AtomicBool, Ordering},
        RwLock,
    },
};

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
        INIT_FLAG.store(true, Ordering::SeqCst);
        let dir = format!("{}/{}", self.db_dir, user_id);
        let db =
            flowy_database::init(&dir).map_err(|e| UserError::Database(format!("😁{:?}", e)))?;

        let mut user_db = DB
            .write()
            .map_err(|e| UserError::Database(format!("Open user db failed. {:?}", e)))?;
        *(user_db) = Some(db);

        set_user_id(Some(user_id.to_owned()));
        Ok(())
    }

    pub(crate) fn close_user_db(&mut self) -> Result<(), UserError> {
        INIT_FLAG.store(false, Ordering::SeqCst);

        let mut write_guard = DB
            .write()
            .map_err(|e| UserError::Database(format!("Close user db failed. {:?}", e)))?;
        *write_guard = None;
        set_user_id(None);

        Ok(())
    }

    pub(crate) fn get_connection(&self, user_id: &str) -> Result<DBConnection, UserError> {
        if !INIT_FLAG.load(Ordering::SeqCst) {
            let _ = self.open_user_db(user_id);
        }

        let thread_user_id = get_user_id();
        if thread_user_id.is_some() {
            if thread_user_id != Some(user_id.to_owned()) {
                let msg = format!(
                    "Database owner does not match. origin: {:?}, current: {}",
                    thread_user_id, user_id
                );
                log::error!("{}", msg);
                return Err(UserError::Database(msg));
            }
        }

        let read_guard = DB
            .read()
            .map_err(|e| UserError::Database(format!("Get user db connection fail. {:?}", e)))?;
        match read_guard.as_ref() {
            None => Err(UserError::Database(
                "Database is not initialization".to_owned(),
            )),
            Some(database) => Ok(database.get_connection()?),
        }
    }
}

thread_local! {
    static USER_ID: RefCell<Option<String>> = RefCell::new(None);
}
fn set_user_id(user_id: Option<String>) {
    USER_ID.with(|id| {
        *id.borrow_mut() = user_id;
    });
}
fn get_user_id() -> Option<String> { USER_ID.with(|id| id.borrow().clone()) }

static INIT_FLAG: AtomicBool = AtomicBool::new(false);

#[cfg(test)]
mod tests {

    #[test]
    fn init_db_test() {
        // init_user_db(".").unwrap();
    }
}
