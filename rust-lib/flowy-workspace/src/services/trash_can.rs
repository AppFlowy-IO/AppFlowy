use crate::{
    entities::trash::{RepeatedTrash, Trash, TrashType},
    errors::{WorkspaceError, WorkspaceResult},
    module::WorkspaceDatabase,
    notify::{send_anonymous_dart_notification, WorkspaceNotification},
    sql_tables::trash::{TrashTable, TrashTableSql},
};
use flowy_database::SqliteConnection;
use std::sync::Arc;
use tokio::sync::{broadcast, mpsc};

#[derive(Clone)]
pub enum TrashEvent {
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
            .send(TrashEvent::Putback(trash_table.ty.into(), vec![trash_table.id], tx))?;

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
    #[tracing::instrument(level = "debug", skip(self, trash, ty, conn), fields(add_trash)  err)]
    pub fn add<T: Into<Trash>>(&self, trash: T, ty: TrashType, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let trash = trash.into();
        let trash_table = TrashTable {
            id: trash.id,
            name: trash.name,
            desc: "".to_owned(),
            modified_time: trash.modified_time,
            create_time: trash.create_time,
            ty: ty.into(),
        };

        tracing::Span::current().record(
            "add_trash",
            &format!("{:?}: {}", &trash_table.ty, trash_table.id).as_str(),
        );

        let _ = TrashTableSql::create_trash(trash_table, &*conn)?;
        let _ = self.notify_dart_trash_did_update(&conn)?;

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
