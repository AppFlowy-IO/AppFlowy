use crate::{
    entities::view::{CreateViewParams, View, ViewTypeIdentifier},
    impl_sql_integer_expression,
    sql_tables::app::AppTable,
};
use diesel::sql_types::Integer;
use flowy_database::schema::{view_table, view_table::dsl};
use flowy_infra::{timestamp, uuid};

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[belongs_to(AppTable, foreign_key = "app_id")]
#[table_name = "view_table"]
pub(crate) struct ViewTable {
    pub id: String,
    pub app_id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub thumbnail: String,
    pub view_type: ViewType,
    pub version: i64,
}

impl ViewTable {
    pub fn new(params: CreateViewParams) -> Self {
        let view_id = uuid();
        let time = timestamp();
        ViewTable {
            id: view_id,
            app_id: params.app_id,
            name: params.name,
            desc: params.desc,
            modified_time: time,
            create_time: time,
            thumbnail: params.thumbnail,
            view_type: params.view_type,
            version: 0,
        }
    }
}

impl std::convert::Into<View> for ViewTable {
    fn into(self) -> View {
        let view_type = match self.view_type {
            ViewType::Docs => ViewTypeIdentifier::Docs,
        };

        View {
            id: self.id,
            app_id: self.app_id,
            name: self.name,
            desc: self.desc,
            view_type,
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "view_table"]
pub struct ViewTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub modified_time: i64,
}

impl ViewTableChangeset {
    pub fn new(id: &str) -> Self {
        ViewTableChangeset {
            id: id.to_string(),
            name: None,
            desc: None,
            modified_time: timestamp(),
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum ViewType {
    Docs = 0,
}

impl std::default::Default for ViewType {
    fn default() -> Self { ViewType::Docs }
}

impl std::convert::From<i32> for ViewType {
    fn from(value: i32) -> Self {
        match value {
            0 => ViewType::Docs,
            o => {
                log::error!("Unsupported view type {}, fallback to ViewType::Docs", o);
                ViewType::Docs
            },
        }
    }
}

impl ViewType {
    pub fn value(&self) -> i32 { *self as i32 }
}

impl_sql_integer_expression!(ViewType);
