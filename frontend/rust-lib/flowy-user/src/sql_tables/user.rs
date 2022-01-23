use crate::entities::{SignInResponse, SignUpResponse, UpdateUserParams};
use flowy_database::schema::user_table;
use flowy_user_data_model::entities::UserProfile;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
    pub(crate) id: String,
    pub(crate) name: String,
    pub(crate) token: String,
    pub(crate) email: String,
    pub(crate) workspace: String, // deprecated
}

impl UserTable {
    pub fn new(id: String, name: String, email: String, token: String) -> Self {
        Self {
            id,
            name,
            email,
            token,
            workspace: "".to_owned(),
        }
    }

    pub fn set_workspace(mut self, workspace: String) -> Self {
        self.workspace = workspace;
        self
    }
}

impl std::convert::From<SignUpResponse> for UserTable {
    fn from(resp: SignUpResponse) -> Self {
        UserTable::new(resp.user_id, resp.name, resp.email, resp.token)
    }
}

impl std::convert::From<SignInResponse> for UserTable {
    fn from(resp: SignInResponse) -> Self {
        UserTable::new(resp.user_id, resp.name, resp.email, resp.token)
    }
}

impl std::convert::From<UserTable> for UserProfile {
    fn from(table: UserTable) -> Self {
        UserProfile {
            id: table.id,
            email: table.email,
            name: table.name,
            token: table.token,
        }
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "user_table"]
pub struct UserTableChangeset {
    pub id: String,
    pub workspace: Option<String>, // deprecated
    pub name: Option<String>,
    pub email: Option<String>,
}

impl UserTableChangeset {
    pub fn new(params: UpdateUserParams) -> Self {
        UserTableChangeset {
            id: params.id,
            workspace: None,
            name: params.name,
            email: params.email,
        }
    }
}
