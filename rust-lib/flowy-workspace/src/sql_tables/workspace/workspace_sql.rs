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
    pub fn write_workspace_table(
        &self,
        workspace_table: WorkspaceTable,
    ) -> Result<(), WorkspaceError> {
        let _ = diesel::insert_into(workspace_table::table)
            .values(workspace_table)
            .execute(&*(self.database.db_connection()?))?;
        Ok(())
    }

    pub fn read_workspace(&self, workspace_id: &str) -> Result<WorkspaceTable, WorkspaceError> {
        let workspace = dsl::workspace_table
            .filter(workspace_table::id.eq(&workspace_id))
            .first::<WorkspaceTable>(&*(self.database.db_connection()?))?;

        Ok(workspace)
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
        unimplemented!()
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
}
