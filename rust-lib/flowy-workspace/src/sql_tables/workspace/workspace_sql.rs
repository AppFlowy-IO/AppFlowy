use crate::{
    errors::WorkspaceError,
    sql_tables::{
        app::AppTable,
        workspace::{WorkspaceTable, WorkspaceTableChangeset},
    },
};
use diesel::SqliteConnection;
use flowy_database::{
    prelude::*,
    schema::{workspace_table, workspace_table::dsl},
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
        let workspaces = match workspace_id {
            None => dsl::workspace_table
                .filter(workspace_table::user_id.eq(user_id))
                .load::<WorkspaceTable>(conn)?,
            Some(workspace_id) => dsl::workspace_table
                .filter(workspace_table::user_id.eq(user_id))
                .filter(workspace_table::id.eq(&workspace_id))
                .load::<WorkspaceTable>(conn)?,
        };

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

    pub(crate) fn read_apps_belong_to_workspace(
        &self,
        workspace_id: &str,
        conn: &SqliteConnection,
    ) -> Result<Vec<AppTable>, WorkspaceError> {
        let workspace_table: WorkspaceTable = dsl::workspace_table
            .filter(workspace_table::id.eq(workspace_id))
            .first::<WorkspaceTable>(conn)?;
        let apps = AppTable::belonging_to(&workspace_table).load::<AppTable>(conn)?;
        Ok(apps)
    }
}
