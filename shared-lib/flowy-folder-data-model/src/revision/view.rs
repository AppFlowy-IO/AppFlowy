use crate::entities::view::{View, ViewDataType};
use crate::entities::RepeatedView;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
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
            desc: view_serde.desc,
            data_type: view_serde.data_type,
            version: view_serde.version,
            belongings: view_serde.belongings.into(),
            modified_time: view_serde.modified_time,
            create_time: view_serde.create_time,
            ext_data: view_serde.ext_data,
            thumbnail: view_serde.thumbnail,
            plugin_type: view_serde.plugin_type,
        }
    }
}

impl std::convert::From<View> for ViewRevision {
    fn from(view: View) -> Self {
        ViewRevision {
            id: view.id,
            belong_to_id: view.belong_to_id,
            name: view.name,
            desc: view.desc,
            data_type: view.data_type,
            version: view.version,
            belongings: view.belongings.into(),
            modified_time: view.modified_time,
            create_time: view.create_time,
            ext_data: view.ext_data,
            thumbnail: view.thumbnail,
            plugin_type: view.plugin_type,
        }
    }
}

impl std::convert::From<Vec<ViewRevision>> for RepeatedView {
    fn from(values: Vec<ViewRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<View>>();
        RepeatedView { items }
    }
}

impl std::convert::From<RepeatedView> for Vec<ViewRevision> {
    fn from(repeated_view: RepeatedView) -> Self {
        repeated_view
            .items
            .into_iter()
            .map(|value| value.into())
            .collect::<Vec<ViewRevision>>()
    }
}
