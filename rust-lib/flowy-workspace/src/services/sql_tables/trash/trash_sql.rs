use flowy_database::{
    prelude::*,
    schema::{trash_table, trash_table::dsl},
    SqliteConnection,
};

use crate::{
    entities::trash::{RepeatedTrash, Trash},
    errors::WorkspaceError,
    services::sql_tables::trash::{TrashTable, TrashTableChangeset},
};

pub struct TrashTableSql {}

impl TrashTableSql {
    pub(crate) fn create_trash(repeated_trash: Vec<Trash>, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        for trash in repeated_trash {
            let trash_table: TrashTable = trash.into();
            match diesel_record_count!(trash_table, &trash_table.id, conn) {
                0 => diesel_insert_table!(trash_table, &trash_table, conn),
                _ => {
                    let changeset = TrashTableChangeset::from(trash_table);
                    diesel_update_table!(trash_table, changeset, conn)
                },
            }
        }

        Ok(())
    }

    pub(crate) fn read_all(conn: &SqliteConnection) -> Result<RepeatedTrash, WorkspaceError> {
        let trash_tables = dsl::trash_table.load::<TrashTable>(conn)?;
        let items = trash_tables.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        Ok(RepeatedTrash { items })
    }

    pub(crate) fn delete_all(conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let _ = diesel::delete(dsl::trash_table).execute(conn)?;
        Ok(())
    }

    pub(crate) fn read(trash_id: &str, conn: &SqliteConnection) -> Result<TrashTable, WorkspaceError> {
        let trash_table = dsl::trash_table
            .filter(trash_table::id.eq(trash_id))
            .first::<TrashTable>(conn)?;
        Ok(trash_table)
    }

    pub(crate) fn delete_trash(trash_id: &str, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_delete_table!(trash_table, trash_id, conn);
        Ok(())
    }
}
