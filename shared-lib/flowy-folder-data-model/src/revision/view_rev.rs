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

    // Maybe app_id or vi
    #[serde(rename = "belong_to_id")]
    pub app_id: String,

    pub name: String,

    pub desc: String,

    #[serde(default)]
    pub data_type: ViewDataTypeRevision,

    pub version: i64, // Deprecated

    pub belongings: Vec<ViewRevision>,

    pub modified_time: i64,

    pub create_time: i64,

    #[serde(default)]
    pub ext_data: String,

    #[serde(default)]
    pub thumbnail: String,

    #[serde(default = "DEFAULT_PLUGIN_TYPE")]
    #[serde(rename = "plugin_type")]
    pub layout: ViewLayoutTypeRevision,
}
const DEFAULT_PLUGIN_TYPE: fn() -> ViewLayoutTypeRevision = || ViewLayoutTypeRevision::Document;

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
    Text = 0,
    Database = 1,
}

impl std::default::Default for ViewDataTypeRevision {
    fn default() -> Self {
        ViewDataTypeRevision::Text
    }
}

#[derive(Eq, PartialEq, Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ViewLayoutTypeRevision {
    Document = 0,
    // The for historical reasons, the value of Grid is not 1.
    Grid = 3,
    Board = 4,
}

impl std::default::Default for ViewLayoutTypeRevision {
    fn default() -> Self {
        ViewLayoutTypeRevision::Document
    }
}
