use crate::{
    entities::app::{App, CreateAppParams, *},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::*,
    services::{server::Server, ViewController},
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};
use flowy_dispatch::prelude::DispatchFuture;

use std::sync::Arc;

pub(crate) struct AppController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<AppTableSql>,
    #[allow(dead_code)]
    view_controller: Arc<ViewController>,
    server: Server,
}

impl AppController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        view_controller: Arc<ViewController>,
        server: Server,
    ) -> Self {
        let sql = Arc::new(AppTableSql { database });
        Self {
            user,
            sql,
            view_controller,
            server,
        }
    }

    pub(crate) fn create_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        // TODO: server
        let app_table = AppTable::new(params);
        let app: App = app_table.clone().into();
        let _ = self.sql.create_app(app_table)?;

        send_observable(&app.workspace_id, WorkspaceObservable::WorkspaceCreateApp);
        Ok(app)
    }

    pub(crate) async fn read_app(&self, app_id: &str, is_trash: bool) -> Result<App, WorkspaceError> {
        let app_table = self.async_read_app(&app_id, is_trash).await?;
        Ok(app_table.into())
    }

    pub(crate) async fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let app = self.sql.delete_app(app_id)?;
        send_observable(&app.workspace_id, WorkspaceObservable::WorkspaceDeleteApp);
        Ok(())
    }

    pub(crate) async fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params);
        let app_id = changeset.id.clone();
        let _ = self.sql.update_app(changeset)?;
        send_observable(&app_id, WorkspaceObservable::AppUpdated);
        Ok(())
    }

    fn async_read_app(&self, app_id: &str, is_trash: bool) -> DispatchFuture<Result<AppTable, WorkspaceError>> {
        let sql = self.sql.clone();
        let app_id = app_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let app_table = sql.read_app(&app_id, is_trash)?;
                // TODO: fetch app from remote server
                Ok(app_table)
            }),
        }
    }
}
