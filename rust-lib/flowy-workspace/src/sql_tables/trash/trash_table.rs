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
impl std::convert::Into<Trash> for TrashTable {
    fn into(self) -> Trash {
        Trash {
            id: self.id,
            name: self.name,
            modified_time: self.modified_time,
            create_time: self.create_time,
            ty: self.ty.into(),
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

impl std::convert::Into<TrashType> for SqlTrashType {
    fn into(self) -> TrashType {
        match self {
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
