use crate::entities::workspace::Workspace;
use crate::revision::AppRevision;
use serde::{Deserialize, Serialize};

#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct WorkspaceRevision {
    pub id: String,

    pub name: String,

    pub desc: String,

    pub apps: Vec<AppRevision>,

    pub modified_time: i64,

    pub create_time: i64,
}

impl std::convert::From<WorkspaceRevision> for Workspace {
    fn from(workspace_serde: WorkspaceRevision) -> Self {
        Workspace {
            id: workspace_serde.id,
            name: workspace_serde.name,
            desc: workspace_serde.desc,
            apps: workspace_serde.apps.into(),
            modified_time: workspace_serde.modified_time,
            create_time: workspace_serde.create_time,
        }
    }
}
