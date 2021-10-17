use crate::{
    entities::view::{CreateViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    notify::send_dart_notification,
    services::{helper::spawn, server::Server},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};

use crate::{
    entities::view::{RepeatedView, ViewIdentifier},
    errors::internal_error,
    module::WorkspaceUser,
    notify::WorkspaceNotification,
    services::{TrashCan, TrashEvent},
};
use flowy_database::SqliteConnection;
use flowy_document::{
    entities::doc::{CreateDocParams, DocDelta, DocIdentifier},
    module::FlowyDocument,
};

use crate::{entities::trash::TrashType, errors::WorkspaceResult};

use futures::{FutureExt, StreamExt};
use std::sync::Arc;

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
        let trash_can = self.trash_can.clone();
        // TODO: rollback anything created before if failed?
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_view(view.clone(), conn)?;
            self.document.create(CreateDocParams::new(&view.id, params.data))?;
            let repeated_view = read_belonging_view(&view.belong_to_id, trash_can, &conn)?;
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

    pub(crate) async fn read_view(&self, params: ViewIdentifier) -> Result<View, WorkspaceError> {
        let conn = self.database.db_connection()?;
        let view_table = ViewTableSql::read_view(&params.view_id, &*conn)?;

        let trash_ids = self.trash_can.trash_ids(&conn)?;
        if trash_ids.contains(&view_table.id) {
            return Err(WorkspaceError::record_not_found());
        }

        let view: View = view_table.into();
        let _ = self.read_view_on_server(params);
        Ok(view)
    }

    pub(crate) fn read_view_tables(&self, ids: Vec<String>) -> Result<Vec<ViewTable>, WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let mut view_tables = vec![];
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            for view_id in ids {
                view_tables.push(ViewTableSql::read_view(&view_id, conn)?);
            }
            Ok(())
        })?;

        Ok(view_tables)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn open_view(&self, params: DocIdentifier) -> Result<DocDelta, WorkspaceError> {
        let edit_context = self.document.open(params, self.database.db_pool()?).await?;
        Ok(edit_context.delta().await.map_err(internal_error)?)
    }

    // belong_to_id will be the app_id or view_id.
    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, WorkspaceError> {
        // TODO: read from server
        let conn = self.database.db_connection()?;
        let repeated_view = read_belonging_view(belong_to_id, self.trash_can.clone(), &conn)?;
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
        send_dart_notification(&view_id, WorkspaceNotification::ViewUpdated)
            .payload(updated_view.clone())
            .send();

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
    fn read_view_on_server(&self, params: ViewIdentifier) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let pool = self.database.db_pool()?;
        // Opti: retry?
        spawn(async move {
            match server.read_view(&token, params).await {
                Ok(Some(view)) => match pool.get() {
                    Ok(conn) => {
                        let view_table = ViewTable::new(view.clone());
                        let result = ViewTableSql::create_view(view_table, &conn);
                        match result {
                            Ok(_) => {
                                send_dart_notification(&view.id, WorkspaceNotification::ViewUpdated)
                                    .payload(view.clone())
                                    .send();
                            },
                            Err(e) => log::error!("Save view failed: {:?}", e),
                        }
                    },
                    Err(e) => log::error!("Require db connection failed: {:?}", e),
                },
                Ok(None) => {},
                Err(e) => log::error!("Read view failed: {:?}", e),
            }
        });
        Ok(())
    }

    fn listen_trash_can_event(&self) {
        let mut rx = self.trash_can.subscribe();
        let database = self.database.clone();
        let document = self.document.clone();
        let trash_can = self.trash_can.clone();
        let _ = tokio::spawn(async move {
            loop {
                let mut stream = Box::pin(rx.recv().into_stream().filter_map(|result| async move {
                    match result {
                        Ok(event) => event.select(TrashType::View),
                        Err(_) => None,
                    }
                }));
                let event: Option<TrashEvent> = stream.next().await;
                match event {
                    Some(event) => {
                        handle_trash_event(database.clone(), document.clone(), trash_can.clone(), event).await
                    },
                    None => {},
                }
            }
        });
    }
}

async fn handle_trash_event(
    database: Arc<dyn WorkspaceDatabase>,
    document: Arc<FlowyDocument>,
    trash_can: Arc<TrashCan>,
    event: TrashEvent,
) {
    let db_result = database.db_connection();

    match event {
        TrashEvent::NewTrash(identifiers, ret) | TrashEvent::Putback(identifiers, ret) => {
            let result = || {
                let conn = &*db_result?;
                let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                    for identifier in identifiers.items {
                        let _ = notify_view_num_changed(&identifier.id, conn, trash_can.clone())?;
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
                    for identifier in identifiers.items {
                        let _ = ViewTableSql::delete_view(&identifier.id, conn)?;
                        let _ = document.delete(identifier.id.clone().into())?;
                        let _ = notify_view_num_changed(&identifier.id, conn, trash_can.clone())?;
                    }
                    Ok(())
                })?;
                Ok::<(), WorkspaceError>(())
            };
            let _ = ret.send(result()).await;
        },
    }
}

#[tracing::instrument(skip(conn, trash_can), err)]
fn notify_view_num_changed(view_id: &str, conn: &SqliteConnection, trash_can: Arc<TrashCan>) -> WorkspaceResult<()> {
    let view_table = ViewTableSql::read_view(view_id, conn)?;
    let repeated_view = read_belonging_view(&view_table.belong_to_id, trash_can, conn)?;

    send_dart_notification(&view_table.belong_to_id, WorkspaceNotification::AppViewsChanged)
        .payload(repeated_view)
        .send();
    Ok(())
}

fn read_belonging_view(
    belong_to_id: &str,
    trash_can: Arc<TrashCan>,
    conn: &SqliteConnection,
) -> WorkspaceResult<RepeatedView> {
    let mut repeated_view = ViewTableSql::read_views(belong_to_id, conn)?;
    let trash_ids = trash_can.trash_ids(conn)?;
    repeated_view.retain(|view| !trash_ids.contains(&view.id));
    Ok(repeated_view)
}
