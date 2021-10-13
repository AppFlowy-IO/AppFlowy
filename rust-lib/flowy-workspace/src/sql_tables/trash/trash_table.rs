use crate::entities::trash::Trash;
use diesel::sql_types::{Binary, Integer};
use flowy_database::schema::trash_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "trash_table"]
pub(crate) struct TrashTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub source: TrashSource,
}
impl std::convert::Into<Trash> for TrashTable {
    fn into(self) -> Trash {
        Trash {
            id: self.id,
            name: self.name,
            modified_time: self.modified_time,
            create_time: self.create_time,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum TrashSource {
    Unknown = 0,
    View    = 1,
}

impl std::default::Default for TrashSource {
    fn default() -> Self { TrashSource::Unknown }
}

impl std::convert::From<i32> for TrashSource {
    fn from(value: i32) -> Self {
        match value {
            0 => TrashSource::Unknown,
            1 => TrashSource::View,
            _o => TrashSource::Unknown,
        }
    }
}

impl TrashSource {
    pub fn value(&self) -> i32 { *self as i32 }
}

impl_sql_integer_expression!(TrashSource);
