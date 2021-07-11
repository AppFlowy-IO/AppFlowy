use crate::{
    entities::{SignInParams, SignUpParams, UserDetail},
    errors::UserError,
    sql_tables::User,
};
use std::sync::RwLock;

pub trait UserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<User, UserError>;
    fn sign_in(&self, params: SignInParams) -> Result<User, UserError>;
    fn get_user_info(&self, user_id: &str) -> Result<UserDetail, UserError>;
    fn sign_out(&self, user_id: &str) -> Result<(), UserError>;
}

pub struct MockUserServer {}

impl UserServer for MockUserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<User, UserError> {
        let user_id = "9527".to_owned();
        // let user_id = uuid();
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

    fn get_user_info(&self, user_id: &str) -> Result<UserDetail, UserError> {
        Err(UserError::Auth("WIP".to_owned()))
    }

    fn sign_out(&self, user_id: &str) -> Result<(), UserError> {
        Err(UserError::Auth("WIP".to_owned()))
    }
}
