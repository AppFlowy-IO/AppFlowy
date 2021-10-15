use crate::{
    entities::view::{CreateViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    notify::send_dart_notification,
    services::{helper::spawn, server::Server},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};

use crate::{
    entities::{
        trash::Trash,
        view::{DeleteViewParams, QueryViewParams, RepeatedView},
    },
    errors::internal_error,
    module::WorkspaceUser,
    notify::WorkspaceNotification,
    services::{TrashCan, TrashEvent},
    sql_tables::trash::TrashSource,
};
use flowy_database::SqliteConnection;
use flowy_document::{
    entities::doc::{CreateDocParams, DocDelta, QueryDocParams},
    module::FlowyDocument,
};

use crate::errors::WorkspaceResult;
use futures::{future, FutureExt, StreamExt, TryStreamExt};
use std::sync::Arc;
use tokio::sync::broadcast::error::RecvError;

pub(crate) struct ViewController {
    user: Arc<dyn WorkspaceUser>,
    server: Server,
    database: Arc<dyn WorkspaceDatabase>,
    trash_can: Arc<TrashCan>,
    document: Arc<FlowyDocument>,
}

impl ViewController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        server: Server,
        trash_can: Arc<TrashCan>,
        document: Arc<FlowyDocument>,
    ) -> Self {
        Self {
            user,
            server,
            database,
            trash_can,
            document,
        }
    }

    pub(crate) fn init(&self) -> Result<(), WorkspaceError> {
        let _ = self.document.init()?;
        self.listen_trash_can_event();
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, params), err)]
    pub(crate) async fn create_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view = self.create_view_on_server(params.clone()).await?;
        let conn = &*self.database.db_connection()?;
        // TODO: rollback anything created before if failed?
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_view(view.clone(), conn)?;
            self.document.create(CreateDocParams::new(&view.id, params.data))?;

            let repeated_view = ViewTableSql::read_views(&view.belong_to_id, conn)?;
            send_dart_notification(&view.belong_to_id, WorkspaceNotification::AppViewsChanged)
                .payload(repeated_view)
                .send();
            Ok(())
        })?;

        Ok(view)
    }

    pub(crate) fn save_view(&self, view: View, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let view_table = ViewTable::new(view);
        let _ = ViewTableSql::create_view(view_table, conn)?;
        Ok(())
    }

    pub(crate) async fn read_view(&self, params: QueryViewParams) -> Result<View, WorkspaceError> {
        let conn = self.database.db_connection()?;
        let view_table = ViewTableSql::read_view(&params.view_id, &*conn)?;
        let view: View = view_table.into();
        let _ = self.read_view_on_server(params);
        Ok(view)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn open_view(&self, params: QueryDocParams) -> Result<DocDelta, WorkspaceError> {
        let edit_context = self.document.open(params, self.database.db_pool()?).await?;
        Ok(edit_context.delta().await.map_err(internal_error)?)
    }

    #[tracing::instrument(level = "debug", skip(self, params), err)]
    pub(crate) async fn delete_view(&self, params: DeleteViewParams) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let _ = self.delete_view_on_server(&params.view_id);

        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let view_table = ViewTableSql::delete_view(&params.view_id, conn)?;
            let _ = self.document.delete(params.into())?;

            let repeated_view = ViewTableSql::read_views(&view_table.belong_to_id, conn)?;

            send_dart_notification(&view_table.belong_to_id, WorkspaceNotification::AppViewsChanged)
                .payload(repeated_view)
                .send();
            Ok(())
        })?;

        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, WorkspaceError> {
        // TODO: read from server
        let conn = self.database.db_connection()?;
        let repeated_view = ViewTableSql::read_views(belong_to_id, &*conn)?;
        Ok(repeated_view)
    }

    #[tracing::instrument(level = "debug", skip(self, params), err)]
    pub(crate) async fn update_view(&self, params: UpdateViewParams) -> Result<View, WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let changeset = ViewTableChangeset::new(params.clone());
        let view_id = changeset.id.clone();

        let updated_view = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = ViewTableSql::update_view(changeset, conn)?;
            let view: View = ViewTableSql::read_view(&view_id, conn)?.into();
            Ok(view)
        })?;

        match params.is_trash {
            None => {
                send_dart_notification(&view_id, WorkspaceNotification::ViewUpdated)
                    .payload(updated_view.clone())
                    .send();
            },
            Some(is_trash) => {
                if is_trash {
                    self.trash_can.add(updated_view.clone(), TrashSource::View, conn)?;
                }
                let _ = notify_view_num_did_change(&updated_view.belong_to_id, conn)?;
            },
        }

        let _ = self.update_view_on_server(params);
        Ok(updated_view)
    }

    pub(crate) async fn apply_doc_delta(&self, params: DocDelta) -> Result<DocDelta, WorkspaceError> {
        let doc = self.document.apply_doc_delta(params).await?;
        Ok(doc)
    }
}

impl ViewController {
    #[tracing::instrument(skip(self), err)]
    async fn create_view_on_server(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let token = self.user.token()?;
        let view = self.server.create_view(&token, params).await?;
        Ok(view)
    }

    #[tracing::instrument(skip(self), err)]
    fn update_view_on_server(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            match server.update_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    fn delete_view_on_server(&self, view_id: &str) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let params = DeleteViewParams {
            view_id: view_id.to_string(),
        };
        spawn(async move {
            match server.delete_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    fn read_view_on_server(&self, params: QueryViewParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            match server.read_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Read view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    fn listen_trash_can_event(&self) {
        let mut rx = self.trash_can.subscribe();
        let database = self.database.clone();
        let _ = tokio::spawn(async move {
            loop {
                let mut stream = Box::pin(rx.recv().into_stream().filter_map(|result| async move {
                    match result {
                        Ok(event) => event.select(TrashSource::View),
                        Err(_) => None,
                    }
                }));
                let event: Option<TrashEvent> = stream.next().await;
                match event {
                    Some(event) => handle_trash_event(database.clone(), event),
                    None => {},
                }
            }
        });
    }
}

fn notify_view_num_did_change(belong_to_id: &str, conn: &SqliteConnection) -> WorkspaceResult<()> {
    let repeated_view = ViewTableSql::read_views(belong_to_id, conn)?;
    send_dart_notification(belong_to_id, WorkspaceNotification::AppViewsChanged)
        .payload(repeated_view)
        .send();
    Ok(())
}

fn handle_trash_event(database: Arc<dyn WorkspaceDatabase>, event: TrashEvent) {
    let db_result = database.db_connection();
    match event {
        TrashEvent::Putback(_, putback_ids, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                    for putback_id in putback_ids {
                        match ViewTableSql::read_view(&putback_id, conn) {
                            Ok(view_table) => {
                                let _ = notify_view_num_did_change(&view_table.belong_to_id, conn)?;
                            },
                            Err(e) => log::error!("Putback view: {} failed: {:?}", putback_id, e),
                        }
                    }
                    Ok(())
                })?;
                Ok::<(), WorkspaceError>(())
            };
            ret.send(result());
        },
        TrashEvent::Delete(_, delete_ids, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                    for delete_id in delete_ids {
                        match ViewTableSql::delete_view(&delete_id, conn) {
                            Ok(view_table) => {
                                let _ = notify_view_num_did_change(&view_table.belong_to_id, conn)?;
                            },
                            Err(e) => log::error!("Delete view: {} failed: {:?}", delete_id, e),
                        }
                    }
                    Ok(())
                })?;
                Ok::<(), WorkspaceError>(())
            };
            ret.send(result());
        },
    }
}
