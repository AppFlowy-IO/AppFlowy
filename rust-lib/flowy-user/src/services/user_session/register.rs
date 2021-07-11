use std::sync::RwLock;

use lazy_static::lazy_static;

use flowy_infra::kv::KVStore;

use crate::{
    entities::{SignInParams, SignUpParams},
    errors::UserError,
    sql_tables::User,
};

lazy_static! {
    pub static ref CURRENT_USER_ID: RwLock<Option<String>> = RwLock::new(None);
}
const USER_ID: &str = "user_id";
pub(crate) fn get_current_user_id() -> Result<Option<String>, UserError> {
    let read_guard = CURRENT_USER_ID
        .read()
        .map_err(|e| UserError::Auth(format!("Read current user id failed. {:?}", e)))?;

    let mut current_user_id = (*read_guard).clone();
    if current_user_id.is_none() {
        current_user_id = KVStore::get_str(USER_ID);
    }

    Ok(current_user_id)
}

pub(crate) fn set_current_user_id(user_id: Option<String>) -> Result<(), UserError> {
    KVStore::set_str(USER_ID, user_id.clone().unwrap_or("".to_owned()));

    let mut current_user_id = CURRENT_USER_ID
        .write()
        .map_err(|e| UserError::Auth(format!("Write current user id failed. {:?}", e)))?;
    *current_user_id = user_id;
    Ok(())
}

pub trait UserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<User, UserError>;
    fn sign_in(&self, params: SignInParams) -> Result<User, UserError>;
}

pub struct MockUserServer {}

impl UserServer for MockUserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<User, UserError> {
        let user_id = "9527".to_owned();
        Ok(User::new(
            user_id,
            params.name,
            params.email,
            params.password,
        ))
    }

    fn sign_in(&self, params: SignInParams) -> Result<User, UserError> {
        let user_id = "9527".to_owned();
        Ok(User::new(
            user_id,
            "".to_owned(),
            params.email,
            params.password,
        ))
    }
}
