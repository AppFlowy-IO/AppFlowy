use crate::{
    entities::{app::*, workspace::*},
    errors::*,
    sql_tables::{app::*, workspace::*},
};
use diesel::ExpressionMethods;
use flowy_database::{
    query_dsl::*,
    schema::{app_table, workspace_table},
    DBConnection,
    RunQueryDsl,
    UserDatabaseConnection,
};
use std::sync::Arc;

macro_rules! diesel_update_table {
    (
        $table_name:ident,
        $changeset:ident,
        $connection:ident
    ) => {
        let filter =
            $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($changeset.id.clone()));
        let affected_row = diesel::update(filter)
            .set($changeset)
            .execute(&*$connection)?;
        debug_assert_eq!(affected_row, 1);
    };
}

pub struct WorkspaceController {
    db: Arc<dyn UserDatabaseConnection>,
}

impl WorkspaceController {
    pub fn new(db: Arc<dyn UserDatabaseConnection>) -> Self { Self { db } }

    pub fn save_workspace(
        &self,
        params: CreateWorkspaceParams,
    ) -> Result<WorkspaceDetail, WorkspaceError> {
        let workspace = Workspace::new(params);
        let conn = self.get_connection()?;
        let detail: WorkspaceDetail = workspace.clone().into();

        let _ = diesel::insert_into(workspace_table::table)
            .values(workspace)
            .execute(&*conn)?;

        Ok(detail)
    }

    pub fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let changeset = WorkspaceChangeset::new(params);
        let conn = self.get_connection()?;
        diesel_update_table!(workspace_table, changeset, conn);

        Ok(())
    }

    pub fn save_app(&self, params: CreateAppParams) -> Result<(), WorkspaceError> {
        let app = App::new(params);
        let conn = self.get_connection()?;
        let _ = diesel::insert_into(app_table::table)
            .values(app)
            .execute(&*conn)?;
        Ok(())
    }

    pub fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppChangeset::new(params);
        let conn = self.get_connection()?;
        diesel_update_table!(app_table, changeset, conn);
        Ok(())
    }
}

impl WorkspaceController {
    fn get_connection(&self) -> Result<DBConnection, WorkspaceError> {
        self.db.get_connection().map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::DatabaseConnectionFail)
                .msg(e)
                .build()
        })
    }
}
