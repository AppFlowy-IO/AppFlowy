use crate::entities::view::{View, ViewDataType};
use crate::entities::{RepeatedView, TrashType};
use crate::revision::TrashRevision;
use serde::{Deserialize, Serialize};

#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct ViewRevision {
    pub id: String,

    pub belong_to_id: String,

    pub name: String,

    pub desc: String,

    #[serde(default)]
    pub data_type: ViewDataType,

    pub version: i64,

    pub belongings: Vec<ViewRevision>,

    pub modified_time: i64,

    pub create_time: i64,

    #[serde(default)]
    pub ext_data: String,

    #[serde(default)]
    pub thumbnail: String,

    #[serde(default = "default_plugin_type")]
    pub plugin_type: i32,
}

fn default_plugin_type() -> i32 {
    0
}

impl std::convert::From<ViewRevision> for View {
    fn from(view_serde: ViewRevision) -> Self {
        View {
            id: view_serde.id,
            belong_to_id: view_serde.belong_to_id,
            name: view_serde.name,
            data_type: view_serde.data_type,
            modified_time: view_serde.modified_time,
            create_time: view_serde.create_time,
            plugin_type: view_serde.plugin_type,
        }
    }
}

impl std::convert::From<ViewRevision> for TrashRevision {
    fn from(view_rev: ViewRevision) -> Self {
        TrashRevision {
            id: view_rev.id,
            name: view_rev.name,
            modified_time: view_rev.modified_time,
            create_time: view_rev.create_time,
            ty: TrashType::TrashView,
        }
    }
}
impl std::convert::From<Vec<ViewRevision>> for RepeatedView {
    fn from(values: Vec<ViewRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<View>>();
        RepeatedView { items }
    }
}
