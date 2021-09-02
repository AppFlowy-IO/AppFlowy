use crate::entities::{
    app::RepeatedApp,
    workspace::{UpdateWorkspaceParams, Workspace},
};
use flowy_database::schema::workspace_table;

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
    pub fn new(workspace: Workspace, user_id: &str) -> Self {
        WorkspaceTable {
            id: workspace.id,
            name: workspace.name,
            desc: workspace.desc,
            modified_time: workspace.modified_time,
            create_time: workspace.create_time,
            user_id: user_id.to_owned(),
            version: 0,
        }
    }
}

impl std::convert::Into<Workspace> for WorkspaceTable {
    fn into(self) -> Workspace {
        Workspace {
            id: self.id,
            name: self.name,
            desc: self.desc,
            apps: RepeatedApp::default(),
            modified_time: self.modified_time,
            create_time: self.create_time,
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
