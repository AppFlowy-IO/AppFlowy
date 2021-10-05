use crate::{
    entities::app::{App, CreateAppParams, *},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    notify::*,
    services::{helper::spawn, server::Server},
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};

use flowy_database::SqliteConnection;
use std::sync::Arc;

pub(crate) struct AppController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<AppTableSql>,
    database: Arc<dyn WorkspaceDatabase>,
    server: Server,
}

impl AppController {
    pub(crate) fn new(user: Arc<dyn WorkspaceUser>, database: Arc<dyn WorkspaceDatabase>, server: Server) -> Self {
        let sql = Arc::new(AppTableSql {});
        Self {
            user,
            sql,
            database,
            server,
        }
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn create_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app = self.create_app_on_server(params).await?;
        let conn = &*self.database.db_connection()?;

        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_app(app.clone(), &*conn)?;
            let apps = self.read_local_apps(&app.workspace_id, &*conn)?;
            dart_notify(&app.workspace_id, WorkspaceObservable::WorkspaceCreateApp)
                .payload(apps)
                .send();
            Ok(())
        })?;

        Ok(app)
    }

    pub(crate) fn save_app(&self, app: App, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let app_table = AppTable::new(app.clone());
        let _ = self.sql.create_app(app_table, &*conn)?;
        Ok(())
    }

    pub(crate) async fn read_app(&self, params: QueryAppParams) -> Result<App, WorkspaceError> {
        let app_table = self
            .sql
            .read_app(&params.app_id, Some(params.is_trash), &*self.database.db_connection()?)?;
        let _ = self.read_app_on_server(params)?;
        Ok(app_table.into())
    }

    pub(crate) async fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let app = self.sql.delete_app(app_id, &*conn)?;
            let apps = self.read_local_apps(&app.workspace_id, &*conn)?;
            dart_notify(&app.workspace_id, WorkspaceObservable::WorkspaceDeleteApp)
                .payload(apps)
                .send();
            Ok(())
        })?;

        let _ = self.delete_app_on_server(app_id);
        Ok(())
    }

    fn read_local_apps(&self, workspace_id: &str, conn: &SqliteConnection) -> Result<RepeatedApp, WorkspaceError> {
        let app_tables = self.sql.read_apps(workspace_id, false, conn)?;
        let apps = app_tables.into_iter().map(|table| table.into()).collect::<Vec<App>>();
        Ok(RepeatedApp { items: apps })
    }

    pub(crate) async fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params.clone());
        let app_id = changeset.id.clone();
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.sql.update_app(changeset, conn)?;
            let app: App = self.sql.read_app(&app_id, None, conn)?.into();
            dart_notify(&app_id, WorkspaceObservable::AppUpdated)
                .payload(app)
                .send();
            Ok(())
        })?;

        let _ = self.update_app_on_server(params)?;
        Ok(())
    }
}

impl AppController {
    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn create_app_on_server(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let token = self.user.token()?;
        let app = self.server.create_app(&token, params).await?;
        Ok(app)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn update_app_on_server(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
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
    fn delete_app_on_server(&self, app_id: &str) -> Result<(), WorkspaceError> {
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
    fn read_app_on_server(&self, params: QueryAppParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            // Opti: retry?
            match server.read_app(&token, params).await {
                Ok(option) => match option {
                    None => {},
                    Some(_app) => {},
                },
                Err(_) => {},
            }
        });
        Ok(())
    }
}
