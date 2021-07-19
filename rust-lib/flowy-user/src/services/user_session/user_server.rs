use crate::{
    entities::{SignInParams, SignUpParams, UserDetail},
    errors::UserError,
    sql_tables::UserTable,
};

pub trait UserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<UserTable, UserError>;
    fn sign_in(&self, params: SignInParams) -> Result<UserTable, UserError>;
    fn get_user_info(&self, user_id: &str) -> Result<UserDetail, UserError>;
    fn sign_out(&self, user_id: &str) -> Result<(), UserError>;
}
