use crate::domain::{UserEmail, UserName, UserPassword};
use flowy_database::schema::user_table;
use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct User {
    #[pb(index = 1)]
    pub(crate) id: String,

    #[pb(index = 2)]
    name: String,

    #[pb(index = 3)]
    email: String,

    #[pb(index = 4)]
    password: String,
}

impl User {
    pub fn new(id: String, name: String, email: String, password: String) -> Self {
        Self {
            id,
            name,
            email,
            password,
        }
    }
}
