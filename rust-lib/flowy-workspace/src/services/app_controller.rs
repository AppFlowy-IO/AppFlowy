use std::{collections::HashSet, sync::Arc};

use futures::{FutureExt, StreamExt};

use flowy_database::SqliteConnection;

use crate::{
    entities::{
        app::{App, CreateAppParams, *},
        trash::TrashType,
    },
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    notify::*,
    services::{helper::spawn, server::Server, TrashCan, TrashEvent},
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};

pub(crate) struct AppController {
    user: Arc<dyn WorkspaceUser>,
    database: Arc<dyn WorkspaceDatabase>,
    trash_can: Arc<TrashCan>,
    server: Server,
}

impl AppController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        trash_can: Arc<TrashCan>,
        server: Server,
    ) -> Self {
        Self {
            user,
            database,
            trash_can,
            server,
        }
    }

    pub fn init(&self) -> Result<(), WorkspaceError> {
        self.listen_trash_can_event();
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, params), fields(name = %params.name) err)]
    pub(crate) async fn create_app_from_params(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app = self.create_app_on_server(params).await?;
        self.create_app(app).await
    }

    pub(crate) async fn create_app(&self, app: App) -> Result<App, WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_app(app.clone(), &*conn)?;
            let _ = notify_apps_changed(&app.workspace_id, self.trash_can.clone(), conn)?;
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
        let conn = self.database.db_connection()?;
        let app_table = AppTableSql::read_app(&params.app_id, &*conn)?;

        let trash_ids = self.trash_can.trash_ids(&conn)?;
        if trash_ids.contains(&app_table.id) {
            return Err(WorkspaceError::record_not_found());
        }

        let _ = self.read_app_on_server(params)?;
        Ok(app_table.into())
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

    pub(crate) fn read_app_tables(&self, ids: Vec<String>) -> Result<Vec<AppTable>, WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let mut app_tables = vec![];
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
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

    fn listen_trash_can_event(&self) {
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
                match stream.next().await {
                    Some(event) => handle_trash_event(database.clone(), trash_can.clone(), event).await,
                    None => {},
                }
            }
        });
    }
}

#[tracing::instrument(level = "trace", skip(database, trash_can))]
async fn handle_trash_event(database: Arc<dyn WorkspaceDatabase>, trash_can: Arc<TrashCan>, event: TrashEvent) {
    let db_result = database.db_connection();
    match event {
        TrashEvent::NewTrash(identifiers, ret) | TrashEvent::Putback(identifiers, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                    for identifier in identifiers.items {
                        let app_table = AppTableSql::read_app(&identifier.id, conn)?;
                        let _ = notify_apps_changed(&app_table.workspace_id, trash_can.clone(), conn)?;
                    }
                    Ok(())
                })?;
                Ok::<(), WorkspaceError>(())
            };
            let _ = ret.send(result()).await;
        },
        TrashEvent::Delete(identifiers, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
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
                Ok::<(), WorkspaceError>(())
            };
            let _ = ret.send(result()).await;
        },
    }
}

#[tracing::instrument(skip(workspace_id, trash_can, conn), err)]
fn notify_apps_changed(workspace_id: &str, trash_can: Arc<TrashCan>, conn: &SqliteConnection) -> WorkspaceResult<()> {
    let repeated_app = read_local_workspace_apps(workspace_id, trash_can, conn)?;
    send_dart_notification(workspace_id, WorkspaceNotification::WorkspaceAppsChanged)
        .payload(repeated_app)
        .send();
    Ok(())
}

pub fn read_local_workspace_apps(
    workspace_id: &str,
    trash_can: Arc<TrashCan>,
    conn: &SqliteConnection,
) -> Result<RepeatedApp, WorkspaceError> {
    let mut app_tables = AppTableSql::read_workspace_apps(workspace_id, false, conn)?;
    let trash_ids = trash_can.trash_ids(conn)?;
    app_tables.retain(|app_table| !trash_ids.contains(&app_table.id));

    let apps = app_tables.into_iter().map(|table| table.into()).collect::<Vec<App>>();
    Ok(RepeatedApp { items: apps })
}

// #[tracing::instrument(level = "debug", skip(self), err)]
// pub(crate) async fn delete_app(&self, app_id: &str) -> Result<(),
// WorkspaceError> {     let conn = &*self.database.db_connection()?;
//     conn.immediate_transaction::<_, WorkspaceError, _>(|| {
//         let app = AppTableSql::delete_app(app_id, &*conn)?;
//         let apps = self.read_local_apps(&app.workspace_id, &*conn)?;
//         send_dart_notification(&app.workspace_id,
// WorkspaceNotification::WorkspaceDeleteApp)             .payload(apps)
//             .send();
//         Ok(())
//     })?;
//
//     let _ = self.delete_app_on_server(app_id);
//     Ok(())
// }
//
// #[tracing::instrument(level = "debug", skip(self), err)]
// fn delete_app_on_server(&self, app_id: &str) -> Result<(), WorkspaceError> {
//     let token = self.user.token()?;
//     let server = self.server.clone();
//     let params = DeleteAppParams {
//         app_id: app_id.to_string(),
//     };
//     spawn(async move {
//         match server.delete_app(&token, params).await {
//             Ok(_) => {},
//             Err(e) => {
//                 // TODO: retry?
//                 log::error!("Delete app failed: {:?}", e);
//             },
//         }
//     });
//     // let action = RetryAction::new(self.server.clone(), self.user.clone(),
// move     // |token, server| {     let params = params.clone();
//     //     async move {
//     //         match server.delete_app(&token, params).await {
//     //             Ok(_) => {},
//     //             Err(e) => log::error!("Delete app failed: {:?}", e),
//     //         }
//     //         Ok::<(), WorkspaceError>(())
//     //     }
//     // });
//     //
//     // spawn_retry(500, 3, action);
//     Ok(())
// }
