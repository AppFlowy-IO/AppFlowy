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

use std::{fmt::Formatter, sync::Arc};
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

    #[tracing::instrument(level = "debug", skip(self), fields(putback)  err)]
    pub async fn putback(&self, trash_id: &str) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let trash_table = TrashTableSql::read(trash_id, &*self.database.db_connection()?)?;
        let _ = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                let _ = TrashTableSql::delete_trash(trash_id, &*conn)?;
                notify_trash_changed(TrashTableSql::read_all(&conn)?);
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
            delete_all: false,
        })?;

        tracing::Span::current().record("putback", &format!("{:?}", &identifier).as_str());
        let _ = self.notify.send(TrashEvent::Putback(vec![identifier].into(), tx));
        let _ = rx.recv().await.unwrap()?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub async fn restore_all(&self) -> WorkspaceResult<()> {
        let repeated_trash = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                let repeated_trash = TrashTableSql::read_all(&*conn)?;
                let _ = TrashTableSql::delete_all(&*conn)?;
                Ok(repeated_trash)
            })
        })
        .unwrap()?;

        let identifiers: TrashIdentifiers = repeated_trash.items.clone().into();
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let _ = self.notify.send(TrashEvent::Putback(identifiers, tx));
        let _ = rx.recv().await;

        notify_trash_changed(RepeatedTrash { items: vec![] });
        let _ = self.delete_all_trash_on_server().await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn delete_all(&self) -> WorkspaceResult<()> {
        let repeated_trash = TrashTableSql::read_all(&*(self.database.db_connection()?))?;
        let trash_identifiers: TrashIdentifiers = repeated_trash.items.clone().into();
        let _ = self.delete_with_identifiers(trash_identifiers.clone()).await?;

        notify_trash_changed(RepeatedTrash { items: vec![] });
        let _ = self.delete_all_trash_on_server().await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn delete(&self, trash_identifiers: TrashIdentifiers) -> WorkspaceResult<()> {
        let _ = self.delete_with_identifiers(trash_identifiers.clone()).await?;
        notify_trash_changed(TrashTableSql::read_all(&*(self.database.db_connection()?))?);
        let _ = self.delete_trash_on_server(trash_identifiers)?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), fields(delete_trash_ids), err)]
    pub async fn delete_with_identifiers(&self, trash_identifiers: TrashIdentifiers) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        tracing::Span::current().record("delete_trash_ids", &format!("{}", trash_identifiers).as_str());
        let _ = self.notify.send(TrashEvent::Delete(trash_identifiers.clone(), tx));

        match rx.recv().await {
            None => {},
            Some(result) => match result {
                Ok(_) => {},
                Err(e) => log::error!("{}", e),
            },
        }

        let conn = self.database.db_connection()?;
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            for trash_identifier in &trash_identifiers.items {
                let _ = TrashTableSql::delete_trash(&trash_identifier.id, &conn)?;
            }
            Ok(())
        })?;
        Ok(())
    }

    // [[ transaction ]]
    // https://www.tutlane.com/tutorial/sqlite/sqlite-transactions-begin-commit-rollback
    // We can use these commands only when we are performing INSERT, UPDATE, and
    // DELETE operations. It’s not possible for us to use these commands to
    // CREATE and DROP tables operations because those are auto-commit in the
    // database.
    #[tracing::instrument(name = "add_trash", level = "debug", skip(self, trash), fields(trash_ids), err)]
    pub async fn add<T: Into<Trash>>(&self, trash: Vec<T>) -> Result<(), WorkspaceError> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let repeated_trash = trash.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        let identifiers = repeated_trash
            .iter()
            .map(|t| t.into())
            .collect::<Vec<TrashIdentifier>>();

        tracing::Span::current().record(
            "trash_ids",
            &format!(
                "{:?}",
                identifiers
                    .iter()
                    .map(|identifier| format!("{:?}:{}", identifier.ty, identifier.id))
                    .collect::<Vec<_>>()
            )
            .as_str(),
        );
        let _ = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                let _ = TrashTableSql::create_trash(repeated_trash.clone(), &*conn)?;
                let _ = self.create_trash_on_server(repeated_trash);

                notify_trash_changed(TrashTableSql::read_all(&conn)?);
                Ok(())
            })?;
            Ok::<(), WorkspaceError>(())
        })
        .unwrap()?;

        let _ = self.notify.send(TrashEvent::NewTrash(identifiers.into(), tx));
        let _ = rx.recv().await.unwrap()?;

        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<TrashEvent> { self.notify.subscribe() }

    pub fn read_trash(&self, conn: &SqliteConnection) -> Result<RepeatedTrash, WorkspaceError> {
        let repeated_trash = TrashTableSql::read_all(&*conn)?;
        let _ = self.read_trash_on_server()?;
        Ok(repeated_trash)
    }

    pub fn trash_ids(&self, conn: &SqliteConnection) -> Result<Vec<String>, WorkspaceError> {
        let ids = TrashTableSql::read_all(&*conn)?
            .into_inner()
            .into_iter()
            .map(|item| item.id)
            .collect::<Vec<String>>();
        Ok(ids)
    }
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
                    tracing::debug!("Remote trash count: {}", repeated_trash.items.len());
                    match pool.get() {
                        Ok(conn) => {
                            let result = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                                let _ = TrashTableSql::create_trash(repeated_trash.items.clone(), &*conn)?;
                                TrashTableSql::read_all(&conn)
                            });

                            match result {
                                Ok(repeated_trash) => {
                                    // FIXME: User may modify the trash(add/putback) before the flying request comes
                                    // back that will cause the trash list to be outdated.
                                    notify_trash_changed(repeated_trash);
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

    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn delete_all_trash_on_server(&self) -> WorkspaceResult<()> {
        let token = self.user.token()?;
        let server = self.server.clone();
        server.delete_trash(&token, TrashIdentifiers::all()).await
    }
}

#[tracing::instrument(skip(repeated_trash), fields(n_trash))]
fn notify_trash_changed(repeated_trash: RepeatedTrash) {
    tracing::Span::current().record("n_trash", &repeated_trash.len());
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

impl std::fmt::Debug for TrashEvent {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            TrashEvent::NewTrash(identifiers, _) => f.write_str(&format!("{:?}", identifiers)),
            TrashEvent::Putback(identifiers, _) => f.write_str(&format!("{:?}", identifiers)),
            TrashEvent::Delete(identifiers, _) => f.write_str(&format!("{:?}", identifiers)),
        }
    }
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
