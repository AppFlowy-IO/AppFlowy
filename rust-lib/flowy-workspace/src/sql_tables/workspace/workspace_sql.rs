use crate::{
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::{
        app::AppTable,
        workspace::{WorkspaceTable, WorkspaceTableChangeset},
    },
};
use flowy_database::{
    prelude::*,
    schema::{workspace_table, workspace_table::dsl},
};
use std::sync::Arc;

pub struct WorkspaceSql {
    pub database: Arc<dyn WorkspaceDatabase>,
}

impl WorkspaceSql {
    pub fn create_workspace(&self, workspace_table: WorkspaceTable) -> Result<(), WorkspaceError> {
        let _ = diesel::insert_into(workspace_table::table)
            .values(workspace_table)
            .execute(&*(self.database.db_connection()?))?;
        Ok(())
    }

    pub fn read_workspaces(
        &self,
        workspace_id: Option<String>,
        user_id: &str,
    ) -> Result<Vec<WorkspaceTable>, WorkspaceError> {
        let mut filter = dsl::workspace_table.filter(workspace_table::user_id.eq(user_id));
        if let Some(workspace_id) = workspace_id {
            filter.filter(workspace_table::id.eq(&workspace_id));
        }

        let workspaces = filter.load::<WorkspaceTable>(&*(self.database.db_connection()?))?;
        Ok(workspaces)
    }

    pub fn update_workspace(
        &self,
        changeset: WorkspaceTableChangeset,
    ) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(workspace_table, changeset, conn);
        Ok(())
    }

    pub fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        diesel_delete_table!(workspace_table, workspace_id, conn);
        Ok(())
    }

    pub(crate) fn read_apps_belong_to_workspace(
        &self,
        workspace_id: &str,
    ) -> Result<Vec<AppTable>, WorkspaceError> {
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

    pub(crate) fn read_workspaces_belong_to_user(
        &self,
        user_id: &str,
    ) -> Result<Vec<WorkspaceTable>, WorkspaceError> {
        let conn = self.database.db_connection()?;
        let workspaces = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let workspaces = dsl::workspace_table
                .filter(workspace_table::user_id.eq(user_id))
                .load::<WorkspaceTable>(&*(conn))?;
            Ok(workspaces)
        })?;

        Ok(workspaces)
    }
}
