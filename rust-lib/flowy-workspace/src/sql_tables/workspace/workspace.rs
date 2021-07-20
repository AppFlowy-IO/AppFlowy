use crate::entities::workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, Workspace};
use flowy_database::schema::workspace_table;
use flowy_infra::{timestamp, uuid};

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable)]
#[table_name = "workspace_table"]
pub struct WorkspaceTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub user_id: String,
    pub version: i64,
}

impl WorkspaceTable {
    #[allow(dead_code)]
    pub fn new(params: CreateWorkspaceParams) -> Self {
        let mut workspace = WorkspaceTable::default();
        workspace.name = params.name;
        workspace.desc = params.desc;
        workspace
    }
}

impl std::default::Default for WorkspaceTable {
    fn default() -> Self {
        let time = timestamp();
        WorkspaceTable {
            id: uuid(),
            name: String::default(),
            desc: String::default(),
            modified_time: time,
            create_time: time,
            user_id: String::default(),
            version: 0,
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "workspace_table"]
pub struct WorkspaceTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl WorkspaceTableChangeset {
    pub fn new(params: UpdateWorkspaceParams) -> Self {
        WorkspaceTableChangeset {
            id: params.id,
            name: params.name,
            desc: params.desc,
        }
    }
}

impl std::convert::Into<Workspace> for WorkspaceTable {
    fn into(self) -> Workspace {
        Workspace {
            id: self.id,
            name: self.name,
            desc: self.desc,
        }
    }
}
