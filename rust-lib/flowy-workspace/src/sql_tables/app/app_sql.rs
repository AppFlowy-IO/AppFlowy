use crate::{
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::app::{AppTable, AppTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{app_table, app_table::dsl},
    SqliteConnection,
};
use std::sync::Arc;

pub struct AppTableSql {
    database: Arc<dyn WorkspaceDatabase>,
}

impl AppTableSql {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self { Self { database } }
}

impl AppTableSql {
    pub(crate) fn create_app(&self, app_table: AppTable) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        let _ = self.create_app_with(app_table, &*conn)?;
        Ok(())
    }

    pub(crate) fn create_app_with(&self, app_table: AppTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        match diesel_record_count!(app_table, &app_table.id, conn) {
            0 => diesel_insert_table!(app_table, &app_table, conn),
            _ => {
                let changeset = AppTableChangeset::from_table(app_table);
                diesel_update_table!(app_table, changeset, conn)
            },
        }
        Ok(())
    }

    pub(crate) fn update_app(&self, changeset: AppTableChangeset) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(app_table, changeset, &*conn);
        Ok(())
    }

    pub(crate) fn read_app(&self, app_id: &str, is_trash: bool) -> Result<AppTable, WorkspaceError> {
        let app_table = dsl::app_table
            .filter(app_table::id.eq(app_id))
            .filter(app_table::is_trash.eq(is_trash))
            .first::<AppTable>(&*(self.database.db_connection()?))?;

        Ok(app_table)
    }

    pub(crate) fn read_apps(&self, workspace_id: &str, is_trash: bool) -> Result<Vec<AppTable>, WorkspaceError> {
        let app_table = dsl::app_table
            .filter(app_table::workspace_id.eq(workspace_id))
            .filter(app_table::is_trash.eq(is_trash))
            .load::<AppTable>(&*(self.database.db_connection()?))?;

        Ok(app_table)
    }

    pub(crate) fn delete_app(&self, app_id: &str) -> Result<AppTable, WorkspaceError> {
        let conn = self.database.db_connection()?;
        // TODO: group into sql transaction
        let app_table = dsl::app_table
            .filter(app_table::id.eq(app_id))
            .first::<AppTable>(&*(self.database.db_connection()?))?;
        diesel_delete_table!(app_table, app_id, conn);
        Ok(app_table)
    }

    // pub(crate) fn read_views_belong_to_app(
    //     &self,
    //     app_id: &str,
    // ) -> Result<Vec<ViewTable>, WorkspaceError> {
    //     let conn = self.database.db_connection()?;
    //
    //     let views = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
    //         let app_table: AppTable = dsl::app_table
    //             .filter(app_table::id.eq(app_id))
    //             .first::<AppTable>(&*(conn))?;
    //         let views =
    // ViewTable::belonging_to(&app_table).load::<ViewTable>(&*conn)?;
    //         Ok(views)
    //     })?;
    //
    //     Ok(views)
    // }
}
