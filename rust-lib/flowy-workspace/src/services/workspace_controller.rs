use crate::{entities::workspace::*, errors::*, module::WorkspaceUser, sql_tables::workspace::*};
use flowy_database::{prelude::*, schema::workspace_table};

use std::sync::Arc;

pub struct WorkspaceController {
    pub user: Arc<dyn WorkspaceUser>,
}

impl WorkspaceController {
    pub fn new(user: Arc<dyn WorkspaceUser>) -> Self { Self { user } }

    pub async fn save_workspace(
        &self,
        params: CreateWorkspaceParams,
    ) -> Result<WorkspaceDetail, WorkspaceError> {
        let workspace = Workspace::new(params);
        let detail: WorkspaceDetail = workspace.clone().into();

        let _ = diesel::insert_into(workspace_table::table)
            .values(workspace)
            .execute(&*(self.user.db_connection()?))?;

        let _ = self.user.set_workspace(&detail.id).await?;

        Ok(detail)
    }

    pub fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let changeset = WorkspaceChangeset::new(params);
        let conn = self.user.db_connection()?;
        diesel_update_table!(workspace_table, changeset, conn);

        Ok(())
    }
}
