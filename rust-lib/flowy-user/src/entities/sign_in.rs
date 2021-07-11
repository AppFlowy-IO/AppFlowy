use crate::entities::{UserEmail, UserPassword};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct SignInRequest {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,
}

#[derive(Default, ProtoBuf)]
pub struct SignInParams {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,
}

impl TryInto<SignInParams> for SignInRequest {
    type Error = String;

    fn try_into(self) -> Result<SignInParams, Self::Error> {
        let email = UserEmail::parse(self.email)?;
        let password = UserPassword::parse(self.password)?;

        Ok(SignInParams {
            email: email.0,
            password: password.0,
        })
    }
}
