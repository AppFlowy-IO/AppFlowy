use crate::domain::{UserEmail, UserPassword};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UserSignInParams {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,
}

#[derive(Default, ProtoBuf)]
pub struct UserSignInRequest {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,
}

impl TryInto<UserSignInRequest> for UserSignInParams {
    type Error = String;

    fn try_into(self) -> Result<UserSignInRequest, Self::Error> {
        let email = UserEmail::parse(self.email)?;
        let password = UserPassword::parse(self.password)?;

        Ok(UserSignInRequest {
            email: email.0,
            password: password.0,
        })
    }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct UserSignInResult {
    #[pb(index = 1)]
    pub is_success: bool,
}

impl UserSignInResult {
    pub fn new(is_success: bool) -> Self { Self { is_success } }
}
