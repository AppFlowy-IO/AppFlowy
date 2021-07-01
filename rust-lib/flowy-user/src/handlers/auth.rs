use crate::domain::{User, UserEmail, UserName};
use bytes::Bytes;
use flowy_sys::prelude::{response_ok, Data, FromBytes, ResponseResult, SystemError, ToBytes};
use std::convert::TryInto;

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(
    name = "User check",
    skip(data),
    fields(
        email = %data.email,
        name = %data.name
    )
)]
pub async fn user_check(data: Data<UserData>) -> ResponseResult<UserStatus, String> {
    let user: User = data.into_inner().try_into()?;

    response_ok(UserStatus { is_login: false })
}

#[derive(serde::Serialize)]
pub struct UserStatus {
    is_login: bool,
}

impl FromBytes for UserData {
    fn parse_from_bytes(bytes: &Vec<u8>) -> Result<UserData, SystemError> { unimplemented!() }
}

impl ToBytes for UserStatus {
    fn into_bytes(self) -> Result<Vec<u8>, SystemError> { unimplemented!() }
}

#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct UserData {
    name: String,
    email: String,
}

impl UserData {
    pub fn new(name: String, email: String) -> Self { Self { name, email } }
}

impl TryInto<User> for UserData {
    type Error = String;

    fn try_into(self) -> Result<User, Self::Error> {
        let name = UserName::parse(self.name)?;
        let email = UserEmail::parse(self.email)?;
        Ok(User::new(name, email))
    }
}
