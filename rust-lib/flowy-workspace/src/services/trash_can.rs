use crate::{
    entities::trash::{RepeatedTrash, Trash, TrashType},
    errors::{WorkspaceError, WorkspaceResult},
    module::WorkspaceDatabase,
    notify::{send_anonymous_dart_notification, WorkspaceNotification},
    sql_tables::trash::TrashTableSql,
};
use crossbeam_utils::thread;
use flowy_database::SqliteConnection;
use std::sync::Arc;
use tokio::sync::{broadcast, mpsc};

#[derive(Clone)]
pub enum TrashEvent {
    NewTrash(TrashType, Vec<String>, mpsc::Sender<WorkspaceResult<()>>),
    Putback(TrashType, Vec<String>, mpsc::Sender<WorkspaceResult<()>>),
    Delete(TrashType, Vec<String>, mpsc::Sender<WorkspaceResult<()>>),
}

impl TrashEvent {
    pub fn select(self, s: TrashType) -> Option<TrashEvent> {
        match &self {
            TrashEvent::Putback(source, _, _) => {
                if source == &s {
                    return Some(self);
                }
            },
            TrashEvent::Delete(source, _, _) => {
                if source == &s {
                    return Some(self);
                }
            },
            TrashEvent::NewTrash(source, _, _) => {
                if source == &s {
                    return Some(self);
                }
            },
        }
        None
    }
}

pub struct TrashCan {
    database: Arc<dyn WorkspaceDatabase>,
    notify: broadcast::Sender<TrashEvent>,
}

impl TrashCan {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self {
        let (tx, _) = broadcast::channel(10);

        Self { database, notify: tx }
    }
    pub fn read_trash(&self) -> Result<RepeatedTrash, WorkspaceError> {
        let conn = self.database.db_connection()?;
        let repeated_trash = TrashTableSql::read_all(&*conn)?;
        Ok(repeated_trash)
    }

    #[tracing::instrument(level = "debug", skip(self), fields(putback)  err)]
    pub async fn putback(&self, trash_id: &str) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let trash_table = TrashTableSql::read(trash_id, &*self.database.db_connection()?)?;
        tracing::Span::current().record(
            "putback",
            &format!("{:?}: {}", &trash_table.ty, trash_table.id).as_str(),
        );
        let _ = self
            .notify
            .send(TrashEvent::Putback(trash_table.ty.into(), vec![trash_table.id], tx));

        let _ = rx.recv().await.unwrap()?;
        let conn = self.database.db_connection()?;
        let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = TrashTableSql::delete_trash(trash_id, &*conn)?;
            let _ = self.notify_dart_trash_did_update(&conn)?;
            Ok(())
        })?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub fn restore_all(&self) -> WorkspaceResult<()> { Ok(()) }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub fn delete_all(&self) -> WorkspaceResult<()> { Ok(()) }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub async fn delete(&self, trash_id: &str) -> WorkspaceResult<()> {
        let (tx, mut rx) = mpsc::channel::<WorkspaceResult<()>>(1);
        let trash_table = TrashTableSql::read(trash_id, &*self.database.db_connection()?)?;
        let _ = self
            .notify
            .send(TrashEvent::Delete(trash_table.ty.into(), vec![trash_table.id], tx));

        let _ = rx.recv().await.unwrap()?;
        let _ = TrashTableSql::delete_trash(trash_id, &*self.database.db_connection()?)?;

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
        let mut ids = vec![];
        let mut trash_type = None;
        let _ = thread::scope(|_s| {
            let conn = self.database.db_connection()?;
            conn.immediate_transaction::<_, WorkspaceError, _>(|| {
                for t in trash {
                    if trash_type == None {
                        trash_type = Some(t.ty.clone());
                    }

                    if trash_type.as_ref().unwrap() != &t.ty {
                        return Err(WorkspaceError::internal());
                    }

                    ids.push(t.id.clone());
                    let _ = TrashTableSql::create_trash(t.into(), &*conn)?;
                }
                Ok(())
            })?;
            Ok::<(), WorkspaceError>(())
        })
        .unwrap()?;

        if let Some(trash_type) = trash_type {
            let _ = self.notify.send(TrashEvent::NewTrash(trash_type, ids, tx));
            let _ = rx.recv().await.unwrap()?;
        }

        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<TrashEvent> { self.notify.subscribe() }

    fn notify_dart_trash_did_update(&self, conn: &SqliteConnection) -> WorkspaceResult<()> {
        // Opti: only push the changeset
        let repeated_trash = TrashTableSql::read_all(conn)?;
        send_anonymous_dart_notification(WorkspaceNotification::TrashUpdated)
            .payload(repeated_trash)
            .send();

        Ok(())
    }
}
