use crate::{entities::parser::*, errors::*};
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

#[derive(Debug, Default, ProtoBuf)]
pub struct SignInResponse {
    #[pb(index = 1)]
    pub uid: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub email: String,

    #[pb(index = 4)]
    pub token: String,
}

impl TryInto<SignInParams> for SignInRequest {
    type Error = UserError;

    fn try_into(self) -> Result<SignInParams, Self::Error> {
        let email = UserEmail::parse(self.email).map_err(|e| ErrorBuilder::new(e).build())?;
        let password =
            UserPassword::parse(self.password).map_err(|e| ErrorBuilder::new(e).build())?;

        Ok(SignInParams {
            email: email.0,
            password: password.0,
        })
    }
}
