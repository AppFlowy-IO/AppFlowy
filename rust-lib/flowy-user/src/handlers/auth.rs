use crate::domain::{User, UserEmail, UserName};
use bytes::Bytes;
use std::convert::TryInto;

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

#[tracing::instrument(name = "User check")]
pub async fn user_check(user_name: String) -> Bytes { unimplemented!() }
