use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Debug, ProtoBuf_Enum)]
pub enum UserStatus {
    Unknown = 0,
    Login   = 1,
    Expired = 2,
}

impl std::default::Default for UserStatus {
    fn default() -> Self { UserStatus::Unknown }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct UserDetail {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub email: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub status: UserStatus,

    #[pb(index = 5)]
    pub workspace: String,
}

use crate::sql_tables::UserTable;
impl std::convert::From<UserTable> for UserDetail {
    fn from(user: UserTable) -> Self {
        UserDetail {
            id: user.id,
            email: user.email,
            name: user.name,
            status: UserStatus::Login,
            workspace: user.workspace,
        }
    }
}
