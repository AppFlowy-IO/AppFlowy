use crate::{
    errors::WorkspaceError,
    sql_tables::app::{AppTable, AppTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{app_table, app_table::dsl},
    SqliteConnection,
};

pub struct AppTableSql {}

impl AppTableSql {
    pub(crate) fn create_app(app_table: AppTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        match diesel_record_count!(app_table, &app_table.id, conn) {
            0 => diesel_insert_table!(app_table, &app_table, conn),
            _ => {
                let changeset = AppTableChangeset::from_table(app_table);
                diesel_update_table!(app_table, changeset, conn)
            },
        }
        Ok(())
    }

    pub(crate) fn update_app(changeset: AppTableChangeset, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_update_table!(app_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn read_app(app_id: &str, conn: &SqliteConnection) -> Result<AppTable, WorkspaceError> {
        let filter = dsl::app_table.filter(app_table::id.eq(app_id)).into_boxed();
        let app_table = filter.first::<AppTable>(conn)?;
        Ok(app_table)
    }

    pub(crate) fn read_workspace_apps(
        workspace_id: &str,
        is_trash: bool,
        conn: &SqliteConnection,
    ) -> Result<Vec<AppTable>, WorkspaceError> {
        let app_table = dsl::app_table
            .filter(app_table::workspace_id.eq(workspace_id))
            .filter(app_table::is_trash.eq(is_trash))
            .order(app_table::create_time.asc())
            .load::<AppTable>(conn)?;

        Ok(app_table)
    }

    pub(crate) fn delete_app(app_id: &str, conn: &SqliteConnection) -> Result<AppTable, WorkspaceError> {
        let app_table = dsl::app_table
            .filter(app_table::id.eq(app_id))
            .first::<AppTable>(conn)?;
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
