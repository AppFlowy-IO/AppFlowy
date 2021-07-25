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

impl TryInto<SignInParams> for SignInRequest {
    type Error = UserError;

    fn try_into(self) -> Result<SignInParams, Self::Error> {
        let email = UserEmail::parse(self.email)
            .map_err(|e| ErrorBuilder::new(UserErrCode::EmailInvalid).msg(e).build())?;
        let password = UserPassword::parse(self.password).map_err(|e| {
            ErrorBuilder::new(UserErrCode::PasswordInvalid)
                .msg(e)
                .build()
        })?;

        Ok(SignInParams {
            email: email.0,
            password: password.0,
        })
    }
}
