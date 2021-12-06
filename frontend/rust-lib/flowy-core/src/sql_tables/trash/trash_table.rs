use crate::entities::trash::{Trash, TrashType};
use diesel::sql_types::Integer;
use flowy_database::schema::trash_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "trash_table"]
pub(crate) struct TrashTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub ty: SqlTrashType,
}
impl std::convert::From<TrashTable> for Trash {
    fn from(table: TrashTable) -> Self {
        Trash {
            id: table.id,
            name: table.name,
            modified_time: table.modified_time,
            create_time: table.create_time,
            ty: table.ty.into(),
        }
    }
}

impl std::convert::From<Trash> for TrashTable {
    fn from(trash: Trash) -> Self {
        TrashTable {
            id: trash.id,
            name: trash.name,
            desc: "".to_owned(),
            modified_time: trash.modified_time,
            create_time: trash.create_time,
            ty: trash.ty.into(),
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "trash_table"]
pub(crate) struct TrashTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub modified_time: i64,
}

impl std::convert::From<TrashTable> for TrashTableChangeset {
    fn from(trash: TrashTable) -> Self {
        TrashTableChangeset {
            id: trash.id,
            name: Some(trash.name),
            modified_time: trash.modified_time,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub(crate) enum SqlTrashType {
    Unknown = 0,
    View    = 1,
    App     = 2,
}

impl std::convert::From<i32> for SqlTrashType {
    fn from(value: i32) -> Self {
        match value {
            0 => SqlTrashType::Unknown,
            1 => SqlTrashType::View,
            2 => SqlTrashType::App,
            _o => SqlTrashType::Unknown,
        }
    }
}

impl_sql_integer_expression!(SqlTrashType);

impl std::convert::From<SqlTrashType> for TrashType {
    fn from(ty: SqlTrashType) -> Self {
        match ty {
            SqlTrashType::Unknown => TrashType::Unknown,
            SqlTrashType::View => TrashType::View,
            SqlTrashType::App => TrashType::App,
        }
    }
}

impl std::convert::From<TrashType> for SqlTrashType {
    fn from(ty: TrashType) -> Self {
        match ty {
            TrashType::Unknown => SqlTrashType::Unknown,
            TrashType::View => SqlTrashType::View,
            TrashType::App => SqlTrashType::App,
        }
    }
}
