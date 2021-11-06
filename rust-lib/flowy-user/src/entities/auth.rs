use crate::{entities::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct SignInRequest {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,

    #[pb(index = 3)]
    pub name: String,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct SignInParams {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub password: String,

    #[pb(index = 3)]
    pub name: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct SignInResponse {
    #[pb(index = 1)]
    pub user_id: String,

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
        let email = UserEmail::parse(self.email).map_err(|e| UserError::code(e))?;
        let password = UserPassword::parse(self.password).map_err(|e| UserError::code(e))?;

        Ok(SignInParams {
            email: email.0,
            password: password.0,
            name: self.name,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct SignUpRequest {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub password: String,
}
impl TryInto<SignUpParams> for SignUpRequest {
    type Error = UserError;

    fn try_into(self) -> Result<SignUpParams, Self::Error> {
        let email = UserEmail::parse(self.email).map_err(|e| UserError::code(e))?;
        let password = UserPassword::parse(self.password).map_err(|e| UserError::code(e))?;
        let name = UserName::parse(self.name).map_err(|e| UserError::code(e))?;

        Ok(SignUpParams {
            email: email.0,
            name: name.0,
            password: password.0,
        })
    }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct SignUpParams {
    #[pb(index = 1)]
    pub email: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub password: String,
}

#[derive(ProtoBuf, Debug, Default)]
pub struct SignUpResponse {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub email: String,

    #[pb(index = 4)]
    pub token: String,
}
