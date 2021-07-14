use crate::{
    entities::{SignInParams, SignUpParams, UserDetail},
    errors::{ErrorBuilder, UserError, UserErrorCode},
    sql_tables::User,
};
use flowy_infra::uuid;

pub trait UserServer {
    fn sign_up(&self, params: SignUpParams) -> Result<User, UserError>;
    fn sign_in(&self, params: SignInParams) -> Result<User, UserError>;
    fn get_user_info(&self, user_id: &str) -> Result<UserDetail, UserError>;
    fn sign_out(&self, user_id: &str) -> Result<(), UserError>;
}
