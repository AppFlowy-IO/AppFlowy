use crate::{
    entities::{
        app::{App, CreateAppParams, *},
        trash::TrashType,
    },
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    notify::*,
    services::{
        app::sql::{AppTable, AppTableChangeset, AppTableSql},
        server::Server,
        TrashController,
        TrashEvent,
    },
};
use flowy_database::SqliteConnection;
use futures::{FutureExt, StreamExt};
use std::{collections::HashSet, sync::Arc};

pub(crate) struct AppController {
    user: Arc<dyn WorkspaceUser>,
    database: Arc<dyn WorkspaceDatabase>,
    trash_can: Arc<TrashController>,
    server: Server,
}

impl AppController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        trash_can: Arc<TrashController>,
        server: Server,
    ) -> Self {
        Self {
            user,
            database,
            trash_can,
            server,
        }
    }

    pub fn init(&self) -> Result<(), FlowyError> {
        self.listen_trash_controller_event();
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, params), fields(name = %params.name) err)]
    pub(crate) async fn create_app_from_params(&self, params: CreateAppParams) -> Result<App, FlowyError> {
        let app = self.create_app_on_server(params).await?;
        self.create_app_on_local(app).await
    }

    pub(crate) async fn create_app_on_local(&self, app: App) -> Result<App, FlowyError> {
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = self.save_app(app.clone(), &*conn)?;
            let _ = notify_apps_changed(&app.workspace_id, self.trash_can.clone(), conn)?;
            Ok(())
        })?;

        Ok(app)
    }

    pub(crate) fn save_app(&self, app: App, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let app_table = AppTable::new(app);
        let _ = AppTableSql::create_app(app_table, &*conn)?;
        Ok(())
    }

    pub(crate) async fn read_app(&self, params: AppId) -> Result<App, FlowyError> {
        let conn = self.database.db_connection()?;
        let app_table = AppTableSql::read_app(&params.app_id, &*conn)?;

        let trash_ids = self.trash_can.read_trash_ids(&conn)?;
        if trash_ids.contains(&app_table.id) {
            return Err(FlowyError::record_not_found());
        }

        let _ = self.read_app_on_server(params)?;
        Ok(app_table.into())
    }

    pub(crate) async fn update_app(&self, params: UpdateAppParams) -> Result<(), FlowyError> {
        let changeset = AppTableChangeset::new(params.clone());
        let app_id = changeset.id.clone();
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
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

    pub(crate) fn read_app_tables(&self, ids: Vec<String>) -> Result<Vec<AppTable>, FlowyError> {
        let conn = &*self.database.db_connection()?;
        let mut app_tables = vec![];
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            for app_id in ids {
                app_tables.push(AppTableSql::read_app(&app_id, conn)?);
            }
            Ok(())
        })?;

        Ok(app_tables)
    }
}

impl AppController {
    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn create_app_on_server(&self, params: CreateAppParams) -> Result<App, FlowyError> {
        let token = self.user.token()?;
        let app = self.server.create_app(&token, params).await?;
        Ok(app)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn update_app_on_server(&self, params: UpdateAppParams) -> Result<(), FlowyError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        tokio::spawn(async move {
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
    fn read_app_on_server(&self, params: AppId) -> Result<(), FlowyError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let pool = self.database.db_pool()?;
        tokio::spawn(async move {
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

    fn listen_trash_controller_event(&self) {
        let mut rx = self.trash_can.subscribe();
        let database = self.database.clone();
        let trash_can = self.trash_can.clone();
        let _ = tokio::spawn(async move {
            loop {
                let mut stream = Box::pin(rx.recv().into_stream().filter_map(|result| async move {
                    match result {
                        Ok(event) => event.select(TrashType::App),
                        Err(_e) => None,
                    }
                }));
                if let Some(event) = stream.next().await {
                    handle_trash_event(database.clone(), trash_can.clone(), event).await
                }
            }
        });
    }
}

#[tracing::instrument(level = "trace", skip(database, trash_can))]
async fn handle_trash_event(database: Arc<dyn WorkspaceDatabase>, trash_can: Arc<TrashController>, event: TrashEvent) {
    let db_result = database.db_connection();
    match event {
        TrashEvent::NewTrash(identifiers, ret) | TrashEvent::Putback(identifiers, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, FlowyError, _>(|| {
                    for identifier in identifiers.items {
                        let app_table = AppTableSql::read_app(&identifier.id, conn)?;
                        let _ = notify_apps_changed(&app_table.workspace_id, trash_can.clone(), conn)?;
                    }
                    Ok(())
                })?;
                Ok::<(), FlowyError>(())
            };
            let _ = ret.send(result()).await;
        },
        TrashEvent::Delete(identifiers, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, FlowyError, _>(|| {
                    let mut notify_ids = HashSet::new();
                    for identifier in identifiers.items {
                        let app_table = AppTableSql::read_app(&identifier.id, conn)?;
                        let _ = AppTableSql::delete_app(&identifier.id, conn)?;
                        notify_ids.insert(app_table.workspace_id);
                    }

                    for notify_id in notify_ids {
                        let _ = notify_apps_changed(&notify_id, trash_can.clone(), conn)?;
                    }
                    Ok(())
                })?;
                Ok::<(), FlowyError>(())
            };
            let _ = ret.send(result()).await;
        },
    }
}

#[tracing::instrument(skip(workspace_id, trash_can, conn), err)]
fn notify_apps_changed(
    workspace_id: &str,
    trash_can: Arc<TrashController>,
    conn: &SqliteConnection,
) -> FlowyResult<()> {
    let repeated_app = read_local_workspace_apps(workspace_id, trash_can, conn)?;
    send_dart_notification(workspace_id, WorkspaceNotification::WorkspaceAppsChanged)
        .payload(repeated_app)
        .send();
    Ok(())
}

pub fn read_local_workspace_apps(
    workspace_id: &str,
    trash_controller: Arc<TrashController>,
    conn: &SqliteConnection,
) -> Result<RepeatedApp, FlowyError> {
    let mut app_tables = AppTableSql::read_workspace_apps(workspace_id, false, conn)?;
    let trash_ids = trash_controller.read_trash_ids(conn)?;
    app_tables.retain(|app_table| !trash_ids.contains(&app_table.id));

    let apps = app_tables.into_iter().map(|table| table.into()).collect::<Vec<App>>();
    Ok(RepeatedApp { items: apps })
}
