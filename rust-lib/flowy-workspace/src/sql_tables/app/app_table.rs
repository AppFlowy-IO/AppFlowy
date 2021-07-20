use crate::{
    entities::{
        app::{App, ColorStyle, CreateAppParams, UpdateAppParams},
        view::RepeatedView,
    },
    impl_sql_binary_expression,
    sql_tables::workspace::WorkspaceTable,
};
use diesel::sql_types::Binary;
use flowy_database::schema::app_table;
use flowy_infra::{timestamp, uuid};
use serde::{Deserialize, Serialize, __private::TryFrom};
use std::convert::TryInto;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[belongs_to(WorkspaceTable, foreign_key = "workspace_id")]
#[table_name = "app_table"]
pub(crate) struct AppTable {
    pub id: String,
    pub workspace_id: String, // equal to #[belongs_to(Workspace, foreign_key = "workspace_id")].
    pub name: String,
    pub desc: String,
    pub color_style: ColorStyleCol,
    pub last_view_id: Option<String>,
    pub modified_time: i64,
    pub create_time: i64,
    pub version: i64,
}

impl AppTable {
    pub fn new(params: CreateAppParams) -> Self {
        let app_id = uuid();
        let time = timestamp();
        Self {
            id: app_id,
            workspace_id: params.workspace_id,
            name: params.name,
            desc: params.desc,
            color_style: params.color_style.into(),
            last_view_id: None,
            modified_time: time,
            create_time: time,
            version: 0,
        }
    }
}

#[derive(Clone, PartialEq, Serialize, Deserialize, Debug, Default, FromSqlRow, AsExpression)]
#[sql_type = "Binary"]
pub(crate) struct ColorStyleCol {
    pub(crate) theme_color: String,
}

impl std::convert::From<ColorStyle> for ColorStyleCol {
    fn from(s: ColorStyle) -> Self {
        Self {
            theme_color: s.theme_color,
        }
    }
}

impl std::convert::TryInto<Vec<u8>> for &ColorStyleCol {
    type Error = String;

    fn try_into(self) -> Result<Vec<u8>, Self::Error> {
        bincode::serialize(self).map_err(|e| format!("{:?}", e))
    }
}

impl std::convert::TryFrom<&[u8]> for ColorStyleCol {
    type Error = String;

    fn try_from(value: &[u8]) -> Result<Self, Self::Error> {
        bincode::deserialize(value).map_err(|e| format!("{:?}", e))
    }
}

impl_sql_binary_expression!(ColorStyleCol);

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "app_table"]
pub struct AppTableChangeset {
    pub id: String,
    pub workspace_id: Option<String>,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl AppTableChangeset {
    pub fn new(params: UpdateAppParams) -> Self {
        AppTableChangeset {
            id: params.app_id,
            workspace_id: params.workspace_id,
            name: params.name,
            desc: params.desc,
        }
    }
}

impl std::convert::Into<App> for AppTable {
    fn into(self) -> App {
        App {
            id: self.id,
            workspace_id: self.workspace_id,
            name: self.name,
            desc: self.desc,
            views: RepeatedView::default(),
        }
    }
}
