use crate::{
    domain::{tables::User, SignUpParams},
    errors::UserError,
};

pub trait UserRegister {
    fn register_user(&self, params: SignUpParams) -> Result<User, UserError>;
}

pub struct MockUserRegister {}

impl UserRegister for MockUserRegister {
    fn register_user(&self, params: SignUpParams) -> Result<User, UserError> {
        let user_id = "9527".to_owned();
        Ok(User::new(
            user_id,
            params.name,
            params.email,
            params.password,
        ))
    }
}
