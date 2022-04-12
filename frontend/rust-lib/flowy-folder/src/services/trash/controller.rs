use crate::{
    dart_notification::{send_anonymous_dart_notification, FolderNotification},
    entities::trash::{RepeatedTrash, RepeatedTrashId, Trash, TrashId, TrashType},
    errors::{FlowyError, FlowyResult},
    event_map::{FolderCouldServiceV1, WorkspaceUser},
    services::persistence::{FolderPersistence, FolderPersistenceTransaction},
};

use std::{fmt::Formatter, sync::Arc};
use tokio::sync::{broadcast, mpsc};

pub struct TrashController {
    persistence: Arc<FolderPersistence>,
    notify: broadcast::Sender<TrashEvent>,
    cloud_service: Arc<dyn FolderCouldServiceV1>,
    user: Arc<dyn WorkspaceUser>,
}

impl TrashController {
    pub fn new(
        persistence: Arc<FolderPersistence>,
        cloud_service: Arc<dyn FolderCouldServiceV1>,
        user: Arc<dyn WorkspaceUser>,
    ) -> Self {
        let (tx, _) = broadcast::channel(10);
        Self {
            persistence,
            notify: tx,
            cloud_service,
            user,
        }
    }

    #[tracing::instrument(level = "debug", skip(self), fields(putback)  err)]
    pub async fn putback(&self, trash_id: &str) -> FlowyResult<()> {
        let (tx, mut rx) = mpsc::channel::<FlowyResult<()>>(1);
        let trash = self
            .persistence
            .begin_transaction(|transaction| {
                let mut repeated_trash = transaction.read_trash(Some(trash_id.to_owned()))?;
                let _ = transaction.delete_trash(Some(vec![trash_id.to_owned()]))?;
                notify_trash_changed(transaction.read_trash(None)?);

                if repeated_trash.is_empty() {
                    return Err(FlowyError::internal().context("Try to put back trash is not exists"));
                }
                Ok(repeated_trash.pop().unwrap())
            })
            .await?;

        let identifier = TrashId {
            id: trash.id,
            ty: trash.ty,
        };

        let _ = self.delete_trash_on_server(RepeatedTrashId {
            items: vec![identifier.clone()],
            delete_all: false,
        })?;

        tracing::Span::current().record("putback", &format!("{:?}", &identifier).as_str());
        let _ = self.notify.send(TrashEvent::Putback(vec![identifier].into(), tx));
        let _ = rx.recv().await.unwrap()?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self)  err)]
    pub async fn restore_all_trash(&self) -> FlowyResult<()> {
        let repeated_trash = self
            .persistence
            .begin_transaction(|transaction| {
                let trash = transaction.read_trash(None);
                let _ = transaction.delete_trash(None);
                trash
            })
            .await?;

        let identifiers: RepeatedTrashId = repeated_trash.items.clone().into();
        let (tx, mut rx) = mpsc::channel::<FlowyResult<()>>(1);
        let _ = self.notify.send(TrashEvent::Putback(identifiers, tx));
        let _ = rx.recv().await;

        notify_trash_changed(RepeatedTrash { items: vec![] });
        let _ = self.delete_all_trash_on_server().await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn delete_all_trash(&self) -> FlowyResult<()> {
        let repeated_trash = self
            .persistence
            .begin_transaction(|transaction| transaction.read_trash(None))
            .await?;
        let trash_identifiers: RepeatedTrashId = repeated_trash.items.clone().into();
        let _ = self.delete_with_identifiers(trash_identifiers.clone()).await?;

        notify_trash_changed(RepeatedTrash { items: vec![] });
        let _ = self.delete_all_trash_on_server().await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn delete(&self, trash_identifiers: RepeatedTrashId) -> FlowyResult<()> {
        let _ = self.delete_with_identifiers(trash_identifiers.clone()).await?;
        let repeated_trash = self
            .persistence
            .begin_transaction(|transaction| transaction.read_trash(None))
            .await?;
        notify_trash_changed(repeated_trash);
        let _ = self.delete_trash_on_server(trash_identifiers)?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), fields(delete_trash_ids), err)]
    pub async fn delete_with_identifiers(&self, trash_identifiers: RepeatedTrashId) -> FlowyResult<()> {
        let (tx, mut rx) = mpsc::channel::<FlowyResult<()>>(1);
        tracing::Span::current().record("delete_trash_ids", &format!("{}", trash_identifiers).as_str());
        let _ = self.notify.send(TrashEvent::Delete(trash_identifiers.clone(), tx));

        match rx.recv().await {
            None => {}
            Some(result) => match result {
                Ok(_) => {}
                Err(e) => log::error!("{}", e),
            },
        }
        let _ = self
            .persistence
            .begin_transaction(|transaction| {
                let ids = trash_identifiers
                    .items
                    .into_iter()
                    .map(|item| item.id)
                    .collect::<Vec<_>>();
                transaction.delete_trash(Some(ids))
            })
            .await?;

        Ok(())
    }

    // [[ transaction ]]
    // https://www.tutlane.com/tutorial/sqlite/sqlite-transactions-begin-commit-rollback
    // We can use these commands only when we are performing INSERT, UPDATE, and
    // DELETE operations. It’s not possible for us to use these commands to
    // CREATE and DROP tables operations because those are auto-commit in the
    // database.
    #[tracing::instrument(name = "add_trash", level = "debug", skip(self, trash), fields(trash_ids), err)]
    pub async fn add<T: Into<Trash>>(&self, trash: Vec<T>) -> Result<(), FlowyError> {
        let (tx, mut rx) = mpsc::channel::<FlowyResult<()>>(1);
        let repeated_trash = trash.into_iter().map(|t| t.into()).collect::<Vec<Trash>>();
        let identifiers = repeated_trash.iter().map(|t| t.into()).collect::<Vec<TrashId>>();

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

        let _ = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.create_trash(repeated_trash.clone())?;
                let _ = self.create_trash_on_server(repeated_trash);
                notify_trash_changed(transaction.read_trash(None)?);
                Ok(())
            })
            .await?;
        let _ = self.notify.send(TrashEvent::NewTrash(identifiers.into(), tx));
        let _ = rx.recv().await.unwrap()?;

        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<TrashEvent> {
        self.notify.subscribe()
    }

    pub async fn read_trash(&self) -> Result<RepeatedTrash, FlowyError> {
        let repeated_trash = self
            .persistence
            .begin_transaction(|transaction| transaction.read_trash(None))
            .await?;
        let _ = self.read_trash_on_server()?;
        Ok(repeated_trash)
    }

    pub fn read_trash_ids<'a>(
        &self,
        transaction: &'a (dyn FolderPersistenceTransaction + 'a),
    ) -> Result<Vec<String>, FlowyError> {
        let ids = transaction
            .read_trash(None)?
            .into_inner()
            .into_iter()
            .map(|item| item.id)
            .collect::<Vec<String>>();
        Ok(ids)
    }
}

impl TrashController {
    #[tracing::instrument(level = "trace", skip(self, trash), err)]
    fn create_trash_on_server<T: Into<RepeatedTrashId>>(&self, trash: T) -> FlowyResult<()> {
        let token = self.user.token()?;
        let trash_identifiers = trash.into();
        let server = self.cloud_service.clone();
        // TODO: retry?
        let _ = tokio::spawn(async move {
            match server.create_trash(&token, trash_identifiers).await {
                Ok(_) => {}
                Err(e) => log::error!("Create trash failed: {:?}", e),
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, trash), err)]
    fn delete_trash_on_server<T: Into<RepeatedTrashId>>(&self, trash: T) -> FlowyResult<()> {
        let token = self.user.token()?;
        let trash_identifiers = trash.into();
        let server = self.cloud_service.clone();
        let _ = tokio::spawn(async move {
            match server.delete_trash(&token, trash_identifiers).await {
                Ok(_) => {}
                Err(e) => log::error!("Delete trash failed: {:?}", e),
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    fn read_trash_on_server(&self) -> FlowyResult<()> {
        let token = self.user.token()?;
        let server = self.cloud_service.clone();
        let persistence = self.persistence.clone();

        tokio::spawn(async move {
            match server.read_trash(&token).await {
                Ok(repeated_trash) => {
                    tracing::debug!("Remote trash count: {}", repeated_trash.items.len());
                    let result = persistence
                        .begin_transaction(|transaction| {
                            let _ = transaction.create_trash(repeated_trash.items.clone())?;
                            transaction.read_trash(None)
                        })
                        .await;

                    match result {
                        Ok(repeated_trash) => {
                            notify_trash_changed(repeated_trash);
                        }
                        Err(e) => log::error!("Save trash failed: {:?}", e),
                    }
                }
                Err(e) => log::error!("Read trash failed: {:?}", e),
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    async fn delete_all_trash_on_server(&self) -> FlowyResult<()> {
        let token = self.user.token()?;
        let server = self.cloud_service.clone();
        server.delete_trash(&token, RepeatedTrashId::all()).await
    }
}

#[tracing::instrument(level = "debug", skip(repeated_trash), fields(n_trash))]
fn notify_trash_changed(repeated_trash: RepeatedTrash) {
    tracing::Span::current().record("n_trash", &repeated_trash.len());
    send_anonymous_dart_notification(FolderNotification::TrashUpdated)
        .payload(repeated_trash)
        .send();
}

#[derive(Clone)]
pub enum TrashEvent {
    NewTrash(RepeatedTrashId, mpsc::Sender<FlowyResult<()>>),
    Putback(RepeatedTrashId, mpsc::Sender<FlowyResult<()>>),
    Delete(RepeatedTrashId, mpsc::Sender<FlowyResult<()>>),
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
            }
            TrashEvent::Delete(mut identifiers, sender) => {
                identifiers.items.retain(|item| item.ty == s);
                if identifiers.items.is_empty() {
                    None
                } else {
                    Some(TrashEvent::Delete(identifiers, sender))
                }
            }
            TrashEvent::NewTrash(mut identifiers, sender) => {
                identifiers.items.retain(|item| item.ty == s);
                if identifiers.items.is_empty() {
                    None
                } else {
                    Some(TrashEvent::NewTrash(identifiers, sender))
                }
            }
        }
    }
}
