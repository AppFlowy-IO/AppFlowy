use crate::errors::UserError;
use flowy_db::DataBase;
use lazy_static::lazy_static;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    RwLock,
};

lazy_static! {
    pub static ref DB: RwLock<Option<DataBase>> = RwLock::new(None);
}

static DB_INIT: AtomicBool = AtomicBool::new(false);

pub fn init_user_db(dir: &str) -> Result<(), UserError> {
    let database = flowy_db::init(dir)?;
    *(DB.write()?) = Some(database);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn init_db_test() { init_user_db(".").unwrap(); }
}
