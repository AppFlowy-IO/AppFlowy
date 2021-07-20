use crate::{
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::{
        app::{AppTable, AppTableChangeset},
        view::ViewTable,
        workspace::WorkspaceTable,
    },
};
use flowy_database::{
    prelude::*,
    schema::{app_table, app_table::dsl},
};
use std::sync::Arc;

pub struct AppTableSql {
    pub database: Arc<dyn WorkspaceDatabase>,
}

impl AppTableSql {
    pub(crate) fn write_app_table(&self, app_table: AppTable) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        let _ = diesel::insert_into(app_table::table)
            .values(app_table)
            .execute(&*conn)?;
        Ok(())
    }

    pub(crate) fn update_app_table(
        &self,
        changeset: AppTableChangeset,
    ) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(app_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn read_app_table(&self, app_id: &str) -> Result<AppTable, WorkspaceError> {
        let app_table = dsl::app_table
            .filter(app_table::id.eq(app_id))
            .first::<AppTable>(&*(self.database.db_connection()?))?;

        Ok(app_table)
    }

    pub(crate) fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> { unimplemented!() }

    pub(crate) fn read_views_belong_to_app(
        &self,
        app_id: &str,
    ) -> Result<Vec<ViewTable>, WorkspaceError> {
        let conn = self.database.db_connection()?;

        let views = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let app_table: AppTable = dsl::app_table
                .filter(app_table::id.eq(app_id))
                .first::<AppTable>(&*(conn))?;
            let views = ViewTable::belonging_to(&app_table).load::<ViewTable>(&*conn)?;
            Ok(views)
        })?;

        Ok(views)
    }
}
