use crate::{entities::trash::RepeatedTrash, errors::WorkspaceError, sql_tables::trash::TrashTable};

use crate::entities::trash::Trash;
use flowy_database::{
    prelude::*,
    schema::{trash_table, trash_table::dsl},
    SqliteConnection,
};

pub struct TrashTableSql {}

impl TrashTableSql {
    pub(crate) fn create_trash(trash_table: TrashTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_insert_table!(trash_table, &trash_table, conn);
        Ok(())
    }

    pub(crate) fn read_all(conn: &SqliteConnection) -> Result<RepeatedTrash, WorkspaceError> {
        let trash_tables = dsl::trash_table.load::<TrashTable>(conn)?;
        let items = trash_tables.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        Ok(RepeatedTrash { items })
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
