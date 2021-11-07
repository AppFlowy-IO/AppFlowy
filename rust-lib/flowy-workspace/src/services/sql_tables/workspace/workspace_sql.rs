use diesel::SqliteConnection;

use flowy_database::{
    prelude::*,
    schema::{workspace_table, workspace_table::dsl},
};

use crate::{
    errors::WorkspaceError,
    services::sql_tables::workspace::{WorkspaceTable, WorkspaceTableChangeset},
};

pub(crate) struct WorkspaceTableSql {}

impl WorkspaceTableSql {
    pub(crate) fn create_workspace(
        &self,
        table: WorkspaceTable,
        conn: &SqliteConnection,
    ) -> Result<(), WorkspaceError> {
        match diesel_record_count!(workspace_table, &table.id, conn) {
            0 => diesel_insert_table!(workspace_table, &table, conn),
            _ => {
                let changeset = WorkspaceTableChangeset::from_table(table);
                diesel_update_table!(workspace_table, changeset, conn);
            },
        }
        Ok(())
    }

    pub(crate) fn read_workspaces(
        &self,
        workspace_id: Option<String>,
        user_id: &str,
        conn: &SqliteConnection,
    ) -> Result<Vec<WorkspaceTable>, WorkspaceError> {
        let mut filter = dsl::workspace_table
            .filter(workspace_table::user_id.eq(user_id))
            .order(workspace_table::create_time.asc())
            .into_boxed();

        if let Some(workspace_id) = workspace_id {
            filter = filter.filter(workspace_table::id.eq(workspace_id.to_owned()));
        };

        let workspaces = filter.load::<WorkspaceTable>(conn)?;

        Ok(workspaces)
    }

    #[allow(dead_code)]
    pub(crate) fn update_workspace(
        &self,
        changeset: WorkspaceTableChangeset,
        conn: &SqliteConnection,
    ) -> Result<(), WorkspaceError> {
        diesel_update_table!(workspace_table, changeset, conn);
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) fn delete_workspace(&self, workspace_id: &str, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_delete_table!(workspace_table, workspace_id, conn);
        Ok(())
    }
}
