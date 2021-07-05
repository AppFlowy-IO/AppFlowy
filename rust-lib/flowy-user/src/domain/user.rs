use crate::domain::{user_email::UserEmail, user_name::UserName};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct User {
    #[pb(index = 1)]
    name: String,

    #[pb(index = 2)]
    email: String,
}

impl User {
    pub fn new(name: UserName, email: UserEmail) -> Self {
        Self {
            name: name.0,
            email: email.0,
        }
    }
}

// #[derive(serde::Serialize)]
// pub struct UserStatus {
//     is_login: bool,
// }
//
// impl FromBytes for UserData {
//     fn parse_from_bytes(_bytes: &Vec<u8>) -> Result<UserData, SystemError> {
// unimplemented!() } }
//
// impl ToBytes for UserStatus {
//     fn into_bytes(self) -> Result<Vec<u8>, SystemError> { unimplemented!() }
// }

#[derive(Debug, ProtoBuf, Default)]
pub struct UserCheck {
    #[pb(index = 1)]
    pub name: String,

    #[pb(index = 2)]
    pub email: String,
}

impl UserCheck {
    pub fn new(name: String, email: String) -> Self { Self { name, email } }
}

impl TryInto<User> for UserCheck {
    type Error = String;

    fn try_into(self) -> Result<User, Self::Error> {
        let name = UserName::parse(self.name)?;
        let email = UserEmail::parse(self.email)?;
        Ok(User::new(name, email))
    }
}
