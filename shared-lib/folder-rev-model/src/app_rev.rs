use crate::{TrashRevision, TrashTypeRevision, ViewRevision};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};

pub fn gen_app_id() -> String {
    nanoid!(10)
}
#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct AppRevision {
    pub id: String,

    pub workspace_id: String,

    pub name: String,

    pub desc: String,

    pub belongings: Vec<ViewRevision>,

    #[serde(default)]
    pub version: i64,

    #[serde(default)]
    pub modified_time: i64,

    #[serde(default)]
    pub create_time: i64,
}

impl std::convert::From<AppRevision> for TrashRevision {
    fn from(app_rev: AppRevision) -> Self {
        TrashRevision {
            id: app_rev.id,
            name: app_rev.name,
            modified_time: app_rev.modified_time,
            create_time: app_rev.create_time,
            ty: TrashTypeRevision::TrashApp,
        }
    }
}
