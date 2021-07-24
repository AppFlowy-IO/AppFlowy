use crate::{
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::view::{ViewTable, ViewTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{view_table, view_table::dsl},
};
use std::sync::Arc;

pub struct ViewTableSql {
    pub database: Arc<dyn WorkspaceDatabase>,
}

impl ViewTableSql {
    pub(crate) fn create_view(&self, view_table: ViewTable) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        let _ = diesel::insert_into(view_table::table)
            .values(view_table)
            .execute(&*conn)?;
        Ok(())
    }

    pub(crate) fn read_view(&self, view_id: &str) -> Result<ViewTable, WorkspaceError> {
        let view_table = dsl::view_table
            .filter(view_table::id.eq(view_id))
            .first::<ViewTable>(&*(self.database.db_connection()?))?;

        Ok(view_table)
    }

    pub(crate) fn update_view(&self, changeset: ViewTableChangeset) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(view_table, changeset, conn);
        Ok(())
    }

    pub fn delete_view(&self, view_id: &str) -> Result<(), WorkspaceError> { unimplemented!() }
}
