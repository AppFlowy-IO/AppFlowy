use crate::{
    entities::app::App,
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::{
        app::{AppTable, AppTableSql},
        workspace::{WorkspaceTable, WorkspaceTableChangeset},
    },
};
use diesel::SqliteConnection;
use flowy_database::{
    macros::*,
    prelude::*,
    schema::{workspace_table, workspace_table::dsl},
    DBConnection,
};
use std::sync::Arc;

pub(crate) struct WorkspaceSql {
    database: Arc<dyn WorkspaceDatabase>,
    app_sql: Arc<AppTableSql>,
}

impl WorkspaceSql {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self {
        Self {
            database: database.clone(),
            app_sql: Arc::new(AppTableSql::new(database.clone())),
        }
    }
}

impl WorkspaceSql {
    pub(crate) fn create_workspace(&self, table: WorkspaceTable) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        //[[immediate_transaction]]
        // https://sqlite.org/lang_transaction.html
        // IMMEDIATE cause the database connection to start a new write immediately,
        // without waiting for a write statement. The BEGIN IMMEDIATE might fail
        // with SQLITE_BUSY if another write transaction is already active on another
        // database connection.
        //
        // EXCLUSIVE is similar to IMMEDIATE in that a write transaction is started
        // immediately. EXCLUSIVE and IMMEDIATE are the same in WAL mode, but in
        // other journaling modes, EXCLUSIVE prevents other database connections from
        // reading the database while the transaction is underway.
        (conn).immediate_transaction::<_, WorkspaceError, _>(|| self.create_workspace_with(table, conn))
    }

    pub(crate) fn create_workspace_with(&self, table: WorkspaceTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        match diesel_record_count!(workspace_table, &table.id, conn) {
            0 => diesel_insert_table!(workspace_table, &table, conn),
            _ => {
                let changeset = WorkspaceTableChangeset::from_table(table);
                diesel_update_table!(workspace_table, changeset, conn);
            },
        }
        Ok(())
    }

    pub(crate) fn create_apps(&self, apps: Vec<App>, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        for app in apps {
            let _ = self.app_sql.create_app_with(AppTable::new(app), conn)?;
        }
        Ok(())
    }

    pub(crate) fn read_workspaces(&self, workspace_id: Option<String>, user_id: &str) -> Result<Vec<WorkspaceTable>, WorkspaceError> {
        let workspaces = match workspace_id {
            None => dsl::workspace_table
                .filter(workspace_table::user_id.eq(user_id))
                .load::<WorkspaceTable>(&*(self.database.db_connection()?))?,
            Some(workspace_id) => dsl::workspace_table
                .filter(workspace_table::user_id.eq(user_id))
                .filter(workspace_table::id.eq(&workspace_id))
                .load::<WorkspaceTable>(&*(self.database.db_connection()?))?,
        };

        Ok(workspaces)
    }

    pub(crate) fn update_workspace(&self, changeset: WorkspaceTableChangeset) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(workspace_table, changeset, &*conn);
        Ok(())
    }

    pub(crate) fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_delete_table!(workspace_table, workspace_id, conn);
        Ok(())
    }

    pub(crate) fn read_apps_belong_to_workspace(&self, workspace_id: &str) -> Result<Vec<AppTable>, WorkspaceError> {
        let conn = self.database.db_connection()?;

        let apps = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let workspace_table: WorkspaceTable = dsl::workspace_table
                .filter(workspace_table::id.eq(workspace_id))
                .first::<WorkspaceTable>(&*(conn))?;
            let apps = AppTable::belonging_to(&workspace_table).load::<AppTable>(&*conn)?;
            Ok(apps)
        })?;

        Ok(apps)
    }

    pub(crate) fn get_db_conn(&self) -> Result<DBConnection, WorkspaceError> {
        let db = self.database.db_connection()?;
        Ok(db)
    }
}
