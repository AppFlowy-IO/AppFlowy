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
        let _ = diesel::insert_into(view_table::table).values(view_table).execute(&*conn)?;
        Ok(())
    }

    pub(crate) fn read_view(&self, view_id: &str, is_trash: bool) -> Result<ViewTable, WorkspaceError> {
        let view_table = dsl::view_table
            .filter(view_table::id.eq(view_id))
            .filter(view_table::is_trash.eq(is_trash))
            .first::<ViewTable>(&*(self.database.db_connection()?))?;

        Ok(view_table)
    }

    pub(crate) fn read_views_belong_to(&self, belong_to_id: &str) -> Result<Vec<ViewTable>, WorkspaceError> {
        let view_tables = dsl::view_table
            .filter(view_table::belong_to_id.eq(belong_to_id))
            .load::<ViewTable>(&*(self.database.db_connection()?))?;

        Ok(view_tables)
    }

    pub(crate) fn update_view(&self, changeset: ViewTableChangeset) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(view_table, changeset, &*conn);
        Ok(())
    }

    pub(crate) fn delete_view(&self, view_id: &str) -> Result<ViewTable, WorkspaceError> {
        let conn = self.database.db_connection()?;

        // TODO: group into transaction
        let view_table = dsl::view_table
            .filter(view_table::id.eq(view_id))
            .first::<ViewTable>(&*(self.database.db_connection()?))?;

        diesel_delete_table!(view_table, view_id, conn);
        Ok(view_table)
    }
}
