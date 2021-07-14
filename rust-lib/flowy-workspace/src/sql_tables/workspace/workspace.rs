use crate::{
    entities::workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceDetail},
    sql_tables::app::App,
};
use flowy_database::schema::{workspace_table, workspace_table::dsl};
use flowy_infra::{timestamp, uuid};
use serde::{Deserialize, Serialize};

#[derive(PartialEq, Clone, Serialize, Deserialize, Debug, Queryable, Identifiable, Insertable)]
#[table_name = "workspace_table"]
#[serde(tag = "type")]
pub struct Workspace {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub user_id: String,
    pub version: i64,
}

impl Workspace {
    #[allow(dead_code)]
    pub fn new(params: CreateWorkspaceParams) -> Self {
        let mut workspace = Workspace::default();
        workspace.name = params.name;
        workspace.desc = params.desc;
        workspace
    }
}

impl std::default::Default for Workspace {
    fn default() -> Self {
        let time = timestamp();
        Workspace {
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
pub struct WorkspaceChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl WorkspaceChangeset {
    pub fn new(params: UpdateWorkspaceParams) -> Self {
        WorkspaceChangeset {
            id: params.id,
            name: params.name,
            desc: params.desc,
        }
    }
}

impl std::convert::Into<WorkspaceDetail> for Workspace {
    fn into(self) -> WorkspaceDetail {
        WorkspaceDetail {
            id: self.id,
            name: self.name,
            desc: self.desc,
        }
    }
}
