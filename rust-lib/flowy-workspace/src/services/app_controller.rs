use crate::{
    entities::{
        app::{App, CreateAppParams, *},
        view::View,
    },
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::*,
    services::ViewController,
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};
use flowy_dispatch::prelude::DispatchFuture;
use std::sync::Arc;

pub struct AppController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<AppTableSql>,
    view_controller: Arc<ViewController>,
}

impl AppController {
    pub fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        view_controller: Arc<ViewController>,
    ) -> Self {
        let sql = Arc::new(AppTableSql { database });
        Self {
            user,
            sql,
            view_controller,
        }
    }

    pub fn save_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app_table = AppTable::new(params);
        let app: App = app_table.clone().into();
        let _ = self.sql.write_app_table(app_table)?;
        send_observable(&app.workspace_id, WorkspaceObservable::WorkspaceAddApp);
        Ok(app)
    }

    pub async fn get_app(&self, app_id: &str) -> Result<App, WorkspaceError> {
        let app_table = self.get_app_table(app_id).await?;
        Ok(app_table.into())
    }

    pub fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params);
        let app_id = changeset.id.clone();
        let _ = self.sql.update_app_table(changeset)?;
        send_observable(&app_id, WorkspaceObservable::AppUpdateDesc);
        Ok(())
    }

    pub async fn get_views(&self, app_id: &str) -> Result<Vec<View>, WorkspaceError> {
        let views = self
            .sql
            .read_views_belong_to_app(app_id)?
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(views)
    }

    fn get_app_table(&self, app_id: &str) -> DispatchFuture<Result<AppTable, WorkspaceError>> {
        let sql = self.sql.clone();
        let app_id = app_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let app_table = sql.read_app_table(&app_id)?;
                // TODO: fetch app from remote server
                Ok(app_table)
            }),
        }
    }
}
