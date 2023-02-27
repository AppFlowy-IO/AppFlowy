use crate::errors::ErrorCode;
use flowy_derive::ProtoBuf;
use std::convert::TryInto;
use user_model::{SignInParams, SignUpParams, UserEmail, UserName, UserPassword};

#[derive(ProtoBuf, Default)]
pub struct SignInPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,

  #[pb(index = 3)]
  pub name: String,
}

impl TryInto<SignInParams> for SignInPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignInParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;

    Ok(SignInParams {
      email: email.0,
      password: password.0,
      name: self.name,
    })
  }
}

#[derive(ProtoBuf, Default)]
pub struct SignUpPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub password: String,
}
impl TryInto<SignUpParams> for SignUpPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignUpParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;
    let name = UserName::parse(self.name)?;

    Ok(SignUpParams {
      email: email.0,
      name: name.0,
      password: password.0,
    })
  }
}
