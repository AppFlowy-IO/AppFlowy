use crate::revision::{TrashRevision, TrashTypeRevision};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
pub fn gen_view_id() -> String {
    nanoid!(10)
}
#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct ViewRevision {
    pub id: String,

    pub belong_to_id: String,

    pub name: String,

    pub desc: String,

    #[serde(default)]
    pub data_type: ViewDataTypeRevision,

    pub version: i64,

    pub belongings: Vec<ViewRevision>,

    pub modified_time: i64,

    pub create_time: i64,

    #[serde(default)]
    pub ext_data: String,

    #[serde(default)]
    pub thumbnail: String,

    #[serde(default = "DEFAULT_PLUGIN_TYPE")]
    pub plugin_type: i32,
}
const DEFAULT_PLUGIN_TYPE: fn() -> i32 = || 0;

impl std::convert::From<ViewRevision> for TrashRevision {
    fn from(view_rev: ViewRevision) -> Self {
        TrashRevision {
            id: view_rev.id,
            name: view_rev.name,
            modified_time: view_rev.modified_time,
            create_time: view_rev.create_time,
            ty: TrashTypeRevision::TrashView,
        }
    }
}

#[derive(Eq, PartialEq, Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ViewDataTypeRevision {
    TextBlock = 0,
    Grid = 1,
}

impl std::default::Default for ViewDataTypeRevision {
    fn default() -> Self {
        ViewDataTypeRevision::TextBlock
    }
}
