use crate::domain::{user_email::UserEmail, user_name::UserName};

pub struct User {
    name: UserName,
    email: UserEmail,
}

impl User {
    pub fn new(name: UserName, email: UserEmail) -> Self { Self { name, email } }
}
