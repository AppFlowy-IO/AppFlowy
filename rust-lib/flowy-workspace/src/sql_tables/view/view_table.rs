use crate::{
    entities::view::{CreateViewParams, RepeatedView, UpdateViewParams, View, ViewType},
    impl_sql_integer_expression,
    sql_tables::app::AppTable,
};
use diesel::sql_types::Integer;
use flowy_database::schema::view_table;
use flowy_infra::{timestamp, uuid};

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[belongs_to(AppTable, foreign_key = "belong_to_id")]
#[table_name = "view_table"]
pub(crate) struct ViewTable {
    pub id: String,
    pub belong_to_id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub thumbnail: String,
    pub view_type: ViewTableType,
    pub version: i64,
    pub is_trash: bool,
}

impl ViewTable {
    pub fn new(params: CreateViewParams) -> Self {
        let view_id = uuid();
        let time = timestamp();
        ViewTable {
            id: view_id,
            belong_to_id: params.belong_to_id,
            name: params.name,
            desc: params.desc,
            modified_time: time,
            create_time: time,
            thumbnail: params.thumbnail,
            view_type: params.view_type,
            version: 0,
            is_trash: false,
        }
    }
}

impl std::convert::Into<View> for ViewTable {
    fn into(self) -> View {
        let view_type = match self.view_type {
            ViewTableType::Docs => ViewType::Doc,
        };

        View {
            id: self.id,
            belong_to_id: self.belong_to_id,
            name: self.name,
            desc: self.desc,
            view_type,
            belongings: RepeatedView::default(),
            version: self.version,
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "view_table"]
pub struct ViewTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub thumbnail: Option<String>,
    pub modified_time: i64,
    pub is_trash: Option<bool>,
}

impl ViewTableChangeset {
    pub fn new(params: UpdateViewParams) -> Self {
        ViewTableChangeset {
            id: params.view_id,
            name: params.name,
            desc: params.desc,
            thumbnail: params.thumbnail,
            modified_time: timestamp(),
            is_trash: params.is_trash,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum ViewTableType {
    Docs = 0,
}

impl std::default::Default for ViewTableType {
    fn default() -> Self { ViewTableType::Docs }
}

impl std::convert::From<i32> for ViewTableType {
    fn from(value: i32) -> Self {
        match value {
            0 => ViewTableType::Docs,
            o => {
                log::error!("Unsupported view type {}, fallback to ViewType::Docs", o);
                ViewTableType::Docs
            },
        }
    }
}

impl ViewTableType {
    pub fn value(&self) -> i32 { *self as i32 }
}

impl_sql_integer_expression!(ViewTableType);
