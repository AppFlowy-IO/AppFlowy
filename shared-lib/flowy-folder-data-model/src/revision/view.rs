use crate::entities::view::{View, ViewDataType};
use crate::entities::{RepeatedView, TrashType, ViewExtData, ViewFilter, ViewGroup, ViewSort};
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

#[derive(Serialize, Deserialize)]
pub struct ViewExtDataRevision {
    pub filter: ViewFilterRevision,
    pub group: ViewGroupRevision,
    pub sort: ViewSortRevision,
}

#[derive(Serialize, Deserialize)]
pub struct ViewFilterRevision {
    pub field_id: String,
}

#[derive(Serialize, Deserialize)]
pub struct ViewGroupRevision {
    pub group_field_id: String,
    pub sub_group_field_id: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct ViewSortRevision {
    field_id: String,
}

impl std::convert::From<String> for ViewExtData {
    fn from(s: String) -> Self {
        match serde_json::from_str::<ViewExtDataRevision>(&s) {
            Ok(data) => data.into(),
            Err(err) => {
                log::error!("{:?}", err);
                ViewExtData::default()
            }
        }
    }
}

impl std::convert::From<ViewExtDataRevision> for ViewExtData {
    fn from(rev: ViewExtDataRevision) -> Self {
        ViewExtData {
            filter: rev.filter.into(),
            group: rev.group.into(),
            sort: rev.sort.into(),
        }
    }
}

impl std::convert::From<ViewFilterRevision> for ViewFilter {
    fn from(rev: ViewFilterRevision) -> Self {
        ViewFilter {
            object_id: rev.field_id,
        }
    }
}

impl std::convert::From<ViewGroupRevision> for ViewGroup {
    fn from(rev: ViewGroupRevision) -> Self {
        ViewGroup {
            group_object_id: rev.group_field_id,
            sub_group_object_id: rev.sub_group_field_id,
        }
    }
}

impl std::convert::From<ViewSortRevision> for ViewSort {
    fn from(rev: ViewSortRevision) -> Self {
        ViewSort {
            object_id: rev.field_id,
        }
    }
}

impl std::convert::From<Vec<ViewRevision>> for RepeatedView {
    fn from(values: Vec<ViewRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<View>>();
        RepeatedView { items }
    }
}
