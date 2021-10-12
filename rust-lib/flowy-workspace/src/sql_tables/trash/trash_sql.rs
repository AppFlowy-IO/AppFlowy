use crate::{entities::trash::RepeatedTrash, errors::WorkspaceError, sql_tables::trash::TrashTable};

use crate::entities::trash::Trash;
use flowy_database::{
    prelude::*,
    schema::{trash_table, trash_table::dsl},
    SqliteConnection,
};

pub struct TrashTableSql {}

impl TrashTableSql {
    pub(crate) fn create_trash(&self, trash_table: TrashTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_insert_table!(trash_table, &trash_table, conn);
        Ok(())
    }

    pub(crate) fn read_trash(&self, conn: &SqliteConnection) -> Result<RepeatedTrash, WorkspaceError> {
        let trash_tables = dsl::trash_table.load::<TrashTable>(conn)?;
        let items = trash_tables.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        Ok(RepeatedTrash { items })
    }

    pub(crate) fn delete_trash(&self, trash_id: &str, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_delete_table!(trash_table, trash_id, conn);
        Ok(())
    }
}
