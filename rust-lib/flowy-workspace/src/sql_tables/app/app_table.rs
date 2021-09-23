use crate::{
    entities::{
        app::{App, ColorStyle, UpdateAppParams},
        view::RepeatedView,
    },
    sql_tables::workspace::WorkspaceTable,
};
use diesel::sql_types::Binary;
use flowy_database::schema::app_table;

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
    pub is_trash: bool,
}

impl AppTable {
    pub fn new(app: App) -> Self {
        Self {
            id: app.id,
            workspace_id: app.workspace_id,
            name: app.name,
            desc: app.desc,
            color_style: ColorStyleCol::default(),
            last_view_id: None,
            modified_time: app.modified_time,
            create_time: app.create_time,
            version: 0,
            is_trash: false,
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

    fn try_into(self) -> Result<Vec<u8>, Self::Error> { bincode::serialize(self).map_err(|e| format!("{:?}", e)) }
}

impl std::convert::TryFrom<&[u8]> for ColorStyleCol {
    type Error = String;

    fn try_from(value: &[u8]) -> Result<Self, Self::Error> { bincode::deserialize(value).map_err(|e| format!("{:?}", e)) }
}

impl_sql_binary_expression!(ColorStyleCol);

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "app_table"]
pub(crate) struct AppTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub is_trash: Option<bool>,
}

impl AppTableChangeset {
    pub(crate) fn new(params: UpdateAppParams) -> Self {
        AppTableChangeset {
            id: params.app_id,
            name: params.name,
            desc: params.desc,
            is_trash: params.is_trash,
        }
    }

    pub(crate) fn from_table(table: AppTable) -> Self {
        AppTableChangeset {
            id: table.id,
            name: Some(table.name),
            desc: Some(table.desc),
            is_trash: Some(table.is_trash),
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
            belongings: RepeatedView::default(),
            version: self.version,
            modified_time: self.modified_time,
            create_time: self.create_time,
        }
    }
}
