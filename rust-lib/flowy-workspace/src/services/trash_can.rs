use crate::{
    entities::trash::{RepeatedTrash, Trash},
    errors::{WorkspaceError, WorkspaceResult},
    module::WorkspaceDatabase,
    notify::{send_anonymous_dart_notification, WorkspaceNotification},
    sql_tables::trash::{TrashSource, TrashTable, TrashTableSql},
};
use flowy_database::SqliteConnection;
use parking_lot::RwLock;
use std::{collections::HashSet, sync::Arc};
use tokio::sync::broadcast;

#[derive(Clone, PartialEq, Eq)]
pub enum TrashEvent {
    Putback(TrashSource, String),
    Delete(TrashSource, String),
}

impl TrashEvent {
    pub fn select(self, s: TrashSource) -> Option<TrashEvent> {
        match &self {
            TrashEvent::Putback(source, id) => {
                if source == &s {
                    return Some(self);
                }
            },
            TrashEvent::Delete(source, id) => {
                if source == &s {
                    return Some(self);
                }
            },
        }
        None
    }

    fn split(self) -> (TrashSource, String) {
        match self {
            TrashEvent::Putback(source, id) => (source, id),
            TrashEvent::Delete(source, id) => (source, id),
        }
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
    pub fn putback(&self, trash_id: &str) -> WorkspaceResult<()> {
        let conn = self.database.db_connection()?;
        let _ = conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let trash_table = TrashTableSql::read(trash_id, &*conn)?;
            let _ = TrashTableSql::delete_trash(trash_id, &*conn)?;
            tracing::Span::current().record(
                "putback",
                &format!("{:?}: {}", &trash_table.source, trash_table.id).as_str(),
            );

            self.notify
                .send(TrashEvent::Putback(trash_table.source, trash_table.id));

            let _ = self.notify_dart_trash_did_update(&conn)?;
            Ok(())
        })?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub fn delete_trash(&self, trash_id: &str) -> WorkspaceResult<()> {
        let conn = self.database.db_connection()?;
        let trash_table = TrashTableSql::read(trash_id, &*conn)?;
        let _ = TrashTableSql::delete_trash(trash_id, &*conn)?;

        let _ = self.notify.send(TrashEvent::Delete(trash_table.source, trash_table.id));
        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<TrashEvent> { self.notify.subscribe() }

    #[tracing::instrument(level = "debug", skip(self, trash, source, conn), fields(add_trash)  err)]
    pub fn add<T: Into<Trash>>(
        &self,
        trash: T,
        source: TrashSource,
        conn: &SqliteConnection,
    ) -> Result<(), WorkspaceError> {
        let trash = trash.into();
        let trash_table = TrashTable {
            id: trash.id,
            name: trash.name,
            desc: "".to_owned(),
            modified_time: trash.modified_time,
            create_time: trash.create_time,
            source,
        };

        tracing::Span::current().record(
            "add_trash",
            &format!("{:?}: {}", &trash_table.source, trash_table.id).as_str(),
        );

        let _ = TrashTableSql::create_trash(trash_table, &*conn)?;
        let _ = self.notify_dart_trash_did_update(&conn)?;

        Ok(())
    }

    fn notify_dart_trash_did_update(&self, conn: &SqliteConnection) -> WorkspaceResult<()> {
        // Opti: only push the changeset
        let repeated_trash = TrashTableSql::read_all(conn)?;
        send_anonymous_dart_notification(WorkspaceNotification::TrashUpdated)
            .payload(repeated_trash)
            .send();

        Ok(())
    }
}
