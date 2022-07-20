use crate::revision::AppRevision;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
pub fn gen_workspace_id() -> String {
    nanoid!(10)
}
#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct WorkspaceRevision {
    pub id: String,

    pub name: String,

    pub desc: String,

    pub apps: Vec<AppRevision>,

    pub modified_time: i64,

    pub create_time: i64,
}
