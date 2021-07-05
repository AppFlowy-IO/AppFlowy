use crate::domain::{UserEmail, UserName, UserPassword};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct User {
    #[pb(index = 1)]
    name: String,

    #[pb(index = 2)]
    email: String,

    #[pb(index = 3)]
    password: String,
}

impl User {
    pub fn new(name: UserName, email: UserEmail, password: UserPassword) -> Self {
        Self {
            name: name.0,
            email: email.0,
            password: password.0,
        }
    }
}
