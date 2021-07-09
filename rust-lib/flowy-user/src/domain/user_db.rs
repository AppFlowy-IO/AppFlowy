use crate::errors::UserError;
use flowy_database::{DBConnection, DataBase};
use lazy_static::lazy_static;
use std::{
    cell::RefCell,
    sync::{
        atomic::{AtomicBool, Ordering},
        RwLock,
    },
};

thread_local! {
    static USER_ID: RefCell<Option<String>> = RefCell::new(None);
}
fn set_user_id(user_id: Option<String>) {
    USER_ID.with(|id| {
        *id.borrow_mut() = user_id;
    });
}
fn get_user_id() -> Option<String> { USER_ID.with(|id| id.borrow().clone()) }

static IS_USER_DB_INIT: AtomicBool = AtomicBool::new(false);

lazy_static! {
    static ref USER_DB_INNER: RwLock<Option<DataBase>> = RwLock::new(None);
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
        let user_dir = format!("{}/{}", self.db_dir, user_id);
        let database = flowy_database::init(&user_dir)?;
        let mut write_guard = USER_DB_INNER.write()?;
        set_user_id(Some(user_id.to_owned()));
        *(write_guard) = Some(database);
        IS_USER_DB_INIT.store(true, Ordering::SeqCst);
        Ok(())
    }

    pub(crate) fn close_user_db(&mut self) -> Result<(), UserError> {
        let mut write_guard = USER_DB_INNER.write()?;
        *write_guard = None;
        set_user_id(None);
        IS_USER_DB_INIT.store(false, Ordering::SeqCst);
        Ok(())
    }

    pub(crate) fn get_connection(&self, user_id: &str) -> Result<DBConnection, UserError> {
        if !IS_USER_DB_INIT.load(Ordering::SeqCst) {
            let _ = self.open_user_db(user_id);
        }

        let thread_user_id = get_user_id();
        if thread_user_id != Some(user_id.to_owned()) {
            let msg = format!(
                "DataBase owner does not match. origin: {:?}, current: {}",
                thread_user_id, user_id
            );
            log::error!("{}", msg);
            return Err(UserError::DBConnection(msg));
        }

        let read_guard = USER_DB_INNER.read()?;
        match read_guard.as_ref() {
            None => Err(UserError::DBNotInit),
            Some(database) => Ok(database.get_connection()?),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn init_db_test() {
        // init_user_db(".").unwrap();
    }
}
