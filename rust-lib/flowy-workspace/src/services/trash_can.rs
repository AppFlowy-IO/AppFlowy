use crate::{
    entities::trash::{RepeatedTrash, Trash, TrashIdentifier, TrashIdentifiers, TrashType},
    errors::{WorkspaceError, WorkspaceResult},
    module::{WorkspaceDatabase, WorkspaceUser},
    notify::{send_anonymous_dart_notification, WorkspaceNotification},
    services::{helper::spawn, server::Server},
    sql_tables::trash::TrashTableSql,
};
use crossbeam_utils::thread;
use flowy_database::SqliteConnection;

use std::sync::Arc;
use tokio::sync::{broadcast, mpsc};

pub struct TrashCan {
    pub database: Arc<dyn WorkspaceDatabase>,
    notify: broadcast::Sender<TrashEvent>,
    server: Server,
    user: Arc<dyn WorkspaceUser>,
}

impl TrashCan {
    pub fn new(database: Arc<dyn WorkspaceDatabase>, server: Server, user: Arc<dyn WorkspaceUser>) -> Self {
        let (tx, _) = broadcast::channel(10);

        Self {
            database,
            notify: tx,
            server,
            user,
        }
    }

    pub(crate) fn init(&self) -> Result<(), WorkspaceError> { Ok(()) }

    pub fn read_trash(&self, conn: &SqliteConnection) -> Result<RepeatedTrash, WorkspaceError> {
        let repeated_trash = TrashTableSql::read_all(&*conn)?;

        let _ = self.read_trash_on_server()?;
        Ok(repeated_trash)
    }

    pub fn trash_ids(&self, conn: &SqliteConnection) -> Result<Vec<String>, WorkspaceError> {
        let ids = TrashTableSql::read_all(&*conn)?
            .take_items()
            .into_iter()
            .map(|item| item.id)
            .collect::<Vec<String>>();
        Ok(ids)
    }

    #[tracing::instrument(level = "debug", skip(self), fields(putback)  err)]
    pub async fn putback(&self, trash_id: &str) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let trash_table = TrashTableSql::read(trash_id, &*self.database.db_connection()?)?;
        let _ = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                let repeated_trash = TrashTableSql::read_all(&conn)?;
                let _ = TrashTableSql::delete_trash(trash_id, &*conn)?;
                notify_trash_num_changed(repeated_trash);
                Ok(())
            })?;
            Ok::<(), WorkspaceError>(())
        })
        .unwrap()?;

        let identifier = TrashIdentifier {
            id: trash_table.id,
            ty: trash_table.ty.into(),
        };

        let _ = self.delete_trash_on_server(TrashIdentifiers {
            items: vec![identifier.clone()],
        })?;

        tracing::Span::current().record("putback", &format!("{:?}", &identifier).as_str());
        let _ = self.notify.send(TrashEvent::Putback(vec![identifier].into(), tx));
        let _ = rx.recv().await.unwrap()?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub fn restore_all(&self) -> WorkspaceResult<()> { Ok(()) }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub fn delete_all(&self) -> WorkspaceResult<()> { Ok(()) }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub async fn delete(&self, trash_identifiers: TrashIdentifiers) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let _ = self.notify.send(TrashEvent::Delete(trash_identifiers.clone(), tx));
        let _ = rx.recv().await.unwrap()?;

        let conn = self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            for trash_identifier in &trash_identifiers.items {
                let _ = TrashTableSql::delete_trash(&trash_identifier.id, &conn)?;
            }
            Ok(())
        })?;

        let _ = self.delete_trash_on_server(trash_identifiers)?;

        Ok(())
    }

    // [[ transaction ]]
    // https://www.tutlane.com/tutorial/sqlite/sqlite-transactions-begin-commit-rollback
    // We can use these commands only when we are performing INSERT, UPDATE, and
    // DELETE operations. It’s not possible for us to use these commands to
    // CREATE and DROP tables operations because those are auto-commit in the
    // database.
    #[tracing::instrument(level = "debug", skip(self, trash), err)]
    pub async fn add<T: Into<Trash>>(&self, trash: Vec<T>) -> Result<(), WorkspaceError> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let trash = trash.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        let mut items = vec![];
        let _ = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                for t in &trash {
                    log::debug!("create trash: {:?}", t);
                    items.push(TrashIdentifier {
                        id: t.id.clone(),
                        ty: t.ty.clone(),
                    });
                    let _ = TrashTableSql::create_trash(t.clone().into(), &*conn)?;
                }
                self.create_trash_on_server(trash);
                let repeated_trash = TrashTableSql::read_all(&conn)?;
                notify_trash_num_changed(repeated_trash);
                Ok(())
            })?;
            Ok::<(), WorkspaceError>(())
        })
        .unwrap()?;

        let _ = self.notify.send(TrashEvent::NewTrash(items.into(), tx));
        let _ = rx.recv().await.unwrap()?;

        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<TrashEvent> { self.notify.subscribe() }
}

impl TrashCan {
    #[tracing::instrument(level = "debug", skip(self, trash), err)]
    fn create_trash_on_server<T: Into<TrashIdentifiers>>(&self, trash: T) -> WorkspaceResult<()> {
        let token = self.user.token()?;
        let trash_identifiers = trash.into();
        let server = self.server.clone();
        // TODO: retry?
        let _ = tokio::spawn(async move {
            match server.create_trash(&token, trash_identifiers).await {
                Ok(_) => {},
                Err(e) => log::error!("Create trash failed: {:?}", e),
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, trash), err)]
    fn delete_trash_on_server<T: Into<TrashIdentifiers>>(&self, trash: T) -> WorkspaceResult<()> {
        let token = self.user.token()?;
        let trash_identifiers = trash.into();
        let server = self.server.clone();
        let _ = tokio::spawn(async move {
            match server.delete_trash(&token, trash_identifiers).await {
                Ok(_) => {},
                Err(e) => log::error!("Delete trash failed: {:?}", e),
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_trash_on_server(&self) -> WorkspaceResult<()> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let pool = self.database.db_pool()?;

        spawn(async move {
            match server.read_trash(&token).await {
                Ok(repeated_trash) => {
                    match pool.get() {
                        Ok(conn) => {
                            let result = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                                for trash in &repeated_trash.items {
                                    let _ = TrashTableSql::create_trash(trash.clone().into(), &*conn)?;
                                }
                                Ok(())
                            });

                            match result {
                                Ok(_) => {
                                    // FIXME: User may modify the trash(add/putback) before the flying request comes
                                    // back that will cause the trash list to be outdated.
                                    // TODO: impl with operation transform
                                    notify_trash_num_changed(repeated_trash);
                                },
                                Err(e) => log::error!("Save trash failed: {:?}", e),
                            }
                        },
                        Err(e) => log::error!("Require db connection failed: {:?}", e),
                    }
                },
                Err(e) => log::error!("Read trash failed: {:?}", e),
            }
        });
        Ok(())
    }
}

#[tracing::instrument(skip(repeated_trash), fields(trash_count))]
fn notify_trash_num_changed(repeated_trash: RepeatedTrash) {
    tracing::Span::current().record("trash_count", &repeated_trash.len());

    send_anonymous_dart_notification(WorkspaceNotification::TrashUpdated)
        .payload(repeated_trash)
        .send();
}

#[derive(Clone)]
pub enum TrashEvent {
    NewTrash(TrashIdentifiers, mpsc::Sender<WorkspaceResult<()>>),
    Putback(TrashIdentifiers, mpsc::Sender<WorkspaceResult<()>>),
    Delete(TrashIdentifiers, mpsc::Sender<WorkspaceResult<()>>),
}

impl TrashEvent {
    pub fn select(self, s: TrashType) -> Option<TrashEvent> {
        match self {
            TrashEvent::Putback(mut identifiers, sender) => {
                identifiers.items.retain(|item| item.ty == s);
                if identifiers.items.is_empty() {
                    None
                } else {
                    Some(TrashEvent::Putback(identifiers, sender))
                }
            },
            TrashEvent::Delete(mut identifiers, sender) => {
                identifiers.items.retain(|item| item.ty == s);
                if identifiers.items.is_empty() {
                    None
                } else {
                    Some(TrashEvent::Delete(identifiers, sender))
                }
            },
            TrashEvent::NewTrash(mut identifiers, sender) => {
                identifiers.items.retain(|item| item.ty == s);
                if identifiers.items.is_empty() {
                    None
                } else {
                    Some(TrashEvent::NewTrash(identifiers, sender))
                }
            },
        }
    }
}
