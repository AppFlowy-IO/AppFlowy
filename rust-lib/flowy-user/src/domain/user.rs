use crate::domain::{user_email::UserEmail, user_name::UserName};
use flowy_derive::ProtoBuf;

pub struct User {
    name: UserName,
    email: UserEmail,
}

impl User {
    pub fn new(name: UserName, email: UserEmail) -> Self { Self { name, email } }
}

#[derive(ProtoBuf, Default)]
pub struct App {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub workspace_id: String, // equal to #[belongs_to(Workspace, foreign_key = "workspace_id")].

    #[pb(index = 3)]
    pub name: String,
}
