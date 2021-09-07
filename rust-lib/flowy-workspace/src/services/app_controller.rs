use crate::{
    entities::app::{App, CreateAppParams, *},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::*,
    services::{helper::spawn, server::Server, ViewController},
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};

use crate::entities::view::RepeatedView;
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
        let sql = Arc::new(AppTableSql::new(database));
        Self {
            user,
            sql,
            view_controller,
            server,
        }
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn create_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app = self.create_app_on_server(params).await?;
        let app_table = AppTable::new(app.clone());
        let _ = self.sql.create_app(app_table)?;

        // Opti: transaction
        let apps = self.read_local_apps(&app.workspace_id)?;
        ObservableBuilder::new(&app.workspace_id, WorkspaceObservable::WorkspaceCreateApp)
            .payload(apps)
            .build();
        Ok(app)
    }

    pub(crate) async fn read_app(&self, params: QueryAppParams) -> Result<App, WorkspaceError> {
        let app_table = self.sql.read_app(&params.app_id, params.is_trash)?;
        let _ = self.read_app_on_server(params).await?;
        Ok(app_table.into())
    }

    pub(crate) async fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let app = self.sql.delete_app(app_id)?;
        let _ = self.delete_app_on_server(app_id).await?;

        // Opti: transaction
        let apps = self.read_local_apps(&app.workspace_id)?;
        ObservableBuilder::new(&app.workspace_id, WorkspaceObservable::WorkspaceDeleteApp)
            .payload(apps)
            .build();
        Ok(())
    }

    fn read_local_apps(&self, workspace_id: &str) -> Result<RepeatedApp, WorkspaceError> {
        let app_tables = self.sql.read_apps(workspace_id, false)?;
        let apps = app_tables.into_iter().map(|table| table.into()).collect::<Vec<App>>();
        Ok(RepeatedApp { items: apps })
    }

    pub(crate) async fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params.clone());
        let app_id = changeset.id.clone();
        let _ = self.sql.update_app(changeset)?;
        let _ = self.update_app_on_server(params).await?;

        let app: App = self.sql.read_app(&app_id, false)?.into();
        ObservableBuilder::new(&app_id, WorkspaceObservable::AppUpdated)
            .payload(app)
            .build();
        Ok(())
    }
}

impl AppController {
    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn create_app_on_server(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let token = self.user.token()?;
        let app = self.server.create_app(&token, params).await?;
        log::info!("😁 {:?}", app);
        Ok(app)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn update_app_on_server(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            match server.update_app(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update app failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn delete_app_on_server(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let params = DeleteAppParams {
            app_id: app_id.to_string(),
        };
        spawn(async move {
            match server.delete_app(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete app failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn read_app_on_server(&self, params: QueryAppParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            // Opti: retry?
            let app = server.read_app(&token, params).await.unwrap();
            match app {
                None => {},
                Some(_) => {},
            }
        });
        Ok(())
    }
}
