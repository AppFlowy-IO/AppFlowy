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
    database: Arc<dyn WorkspaceDatabase>,
    server: Server,
}

impl AppController {
    pub(crate) fn new(user: Arc<dyn WorkspaceUser>, database: Arc<dyn WorkspaceDatabase>, server: Server) -> Self {
        Self { user, database, server }
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn create_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app = self.create_app_on_server(params).await?;
        let conn = &*self.database.db_connection()?;

        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_app(app.clone(), &*conn)?;
            let apps = self.read_local_apps(&app.workspace_id, &*conn)?;
            send_dart_notification(&app.workspace_id, WorkspaceNotification::WorkspaceCreateApp)
                .payload(apps)
                .send();
            Ok(())
        })?;

        Ok(app)
    }

    pub(crate) fn save_app(&self, app: App, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let app_table = AppTable::new(app.clone());
        let _ = AppTableSql::create_app(app_table, &*conn)?;
        Ok(())
    }

    pub(crate) async fn read_app(&self, params: AppIdentifier) -> Result<App, WorkspaceError> {
        let app_table = AppTableSql::read_app(&params.app_id, &*self.database.db_connection()?)?;
        let _ = self.read_app_on_server(params)?;
        Ok(app_table.into())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let app = AppTableSql::delete_app(app_id, &*conn)?;
            let apps = self.read_local_apps(&app.workspace_id, &*conn)?;
            send_dart_notification(&app.workspace_id, WorkspaceNotification::WorkspaceDeleteApp)
                .payload(apps)
                .send();
            Ok(())
        })?;

        let _ = self.delete_app_on_server(app_id);
        Ok(())
    }

    fn read_local_apps(&self, workspace_id: &str, conn: &SqliteConnection) -> Result<RepeatedApp, WorkspaceError> {
        let app_tables = AppTableSql::read_apps(workspace_id, false, conn)?;
        let apps = app_tables.into_iter().map(|table| table.into()).collect::<Vec<App>>();
        Ok(RepeatedApp { items: apps })
    }

    pub(crate) async fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params.clone());
        let app_id = changeset.id.clone();
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = AppTableSql::update_app(changeset, conn)?;
            let app: App = AppTableSql::read_app(&app_id, conn)?.into();
            send_dart_notification(&app_id, WorkspaceNotification::AppUpdated)
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
        // let action = RetryAction::new(self.server.clone(), self.user.clone(), move
        // |token, server| {     let params = params.clone();
        //     async move {
        //         match server.delete_app(&token, params).await {
        //             Ok(_) => {},
        //             Err(e) => log::error!("Delete app failed: {:?}", e),
        //         }
        //         Ok::<(), WorkspaceError>(())
        //     }
        // });
        //
        // spawn_retry(500, 3, action);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_app_on_server(&self, params: AppIdentifier) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let pool = self.database.db_pool()?;
        spawn(async move {
            // Opti: retry?
            match server.read_app(&token, params).await {
                Ok(Some(app)) => match pool.get() {
                    Ok(conn) => {
                        let app_table = AppTable::new(app.clone());
                        let result = AppTableSql::create_app(app_table, &*conn);
                        match result {
                            Ok(_) => {
                                send_dart_notification(&app.id, WorkspaceNotification::AppUpdated)
                                    .payload(app)
                                    .send();
                            },
                            Err(e) => log::error!("Save app failed: {:?}", e),
                        }
                    },
                    Err(e) => log::error!("Require db connection failed: {:?}", e),
                },
                Ok(None) => {},
                Err(e) => log::error!("Read app failed: {:?}", e),
            }
        });
        Ok(())
    }
}
