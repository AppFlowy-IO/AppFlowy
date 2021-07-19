use crate::entities::UpdateUserParams;
use flowy_database::schema::user_table;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
    pub(crate) id: String,
    pub(crate) name: String,
    pub(crate) password: String,
    pub(crate) email: String,
    pub(crate) workspace: String,
}

impl UserTable {
    pub fn new(id: String, name: String, email: String, password: String) -> Self {
        Self {
            id,
            name,
            email,
            password,
            workspace: "".to_owned(),
        }
    }

    pub fn set_workspace(mut self, workspace: String) -> Self {
        self.workspace = workspace;
        self
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "user_table"]
pub struct UserTableChangeset {
    pub id: String,
    pub workspace: Option<String>,
    pub name: Option<String>,
    pub email: Option<String>,
    pub password: Option<String>,
}

impl UserTableChangeset {
    pub fn new(params: UpdateUserParams) -> Self {
        UserTableChangeset {
            id: params.id,
            workspace: params.workspace,
            name: params.name,
            email: params.email,
            password: params.password,
        }
    }
}
