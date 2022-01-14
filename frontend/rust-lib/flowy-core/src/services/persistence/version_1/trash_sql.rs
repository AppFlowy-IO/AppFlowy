use crate::{
    entities::trash::{RepeatedTrash, Trash, TrashType},
    errors::FlowyError,
};
use diesel::sql_types::Integer;
use flowy_database::{
    prelude::*,
    schema::{trash_table, trash_table::dsl},
    SqliteConnection,
};

pub struct TrashTableSql();
impl TrashTableSql {
    pub(crate) fn create_trash(trashes: Vec<Trash>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        for trash in trashes {
            let trash_table: TrashTable = trash.into();
            match diesel_record_count!(trash_table, &trash_table.id, conn) {
                0 => diesel_insert_table!(trash_table, &trash_table, conn),
                _ => {
                    let changeset = TrashChangeset::from(trash_table);
                    diesel_update_table!(trash_table, changeset, conn)
                },
            }
        }

        Ok(())
    }

    pub(crate) fn read_all(conn: &SqliteConnection) -> Result<RepeatedTrash, FlowyError> {
        let trash_tables = dsl::trash_table.load::<TrashTable>(conn)?;
        let items = trash_tables.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        Ok(RepeatedTrash { items })
    }

    pub(crate) fn delete_all(conn: &SqliteConnection) -> Result<(), FlowyError> {
        let _ = diesel::delete(dsl::trash_table).execute(conn)?;
        Ok(())
    }

    pub(crate) fn read(trash_id: &str, conn: &SqliteConnection) -> Result<TrashTable, FlowyError> {
        let trash_table = dsl::trash_table
            .filter(trash_table::id.eq(trash_id))
            .first::<TrashTable>(conn)?;
        Ok(trash_table)
    }

    pub(crate) fn delete_trash(trash_id: &str, conn: &SqliteConnection) -> Result<(), FlowyError> {
        diesel_delete_table!(trash_table, trash_id, conn);
        Ok(())
    }
}

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
pub(crate) struct TrashChangeset {
    pub id: String,
    pub name: Option<String>,
    pub modified_time: i64,
}

impl std::convert::From<TrashTable> for TrashChangeset {
    fn from(trash: TrashTable) -> Self {
        TrashChangeset {
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
