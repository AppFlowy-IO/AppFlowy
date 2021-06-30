use crate::domain::{User, UserEmail, UserName};
use bytes::Bytes;
use flowy_sys::prelude::{In, Out};
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
pub async fn user_check(data: In<UserData>) -> Out<UserData> { panic!("") }

#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct UserData {
    name: String,
    email: String,
}

impl TryInto<User> for UserData {
    type Error = String;

    fn try_into(self) -> Result<User, Self::Error> {
        let name = UserName::parse(self.name)?;
        let email = UserEmail::parse(self.email)?;
        Ok(User::new(name, email))
    }
}
