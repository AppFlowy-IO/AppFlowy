use crate::{
    context::FlowyPersistence,
    services::{
        folder::ws_actor::{FolderWSActorMessage, FolderWebSocketActor},
        web_socket::{WSClientData, WebSocketReceiver},
    },
};
use std::fmt::{Debug, Formatter};

use crate::{context::FolderRevisionKV, services::kv::revision_kv::revisions_to_key_value_items};
use flowy_collaboration::{
    entities::folder_info::FolderInfo,
    errors::CollaborateError,
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    server_folder::{FolderCloudPersistence, ServerFolderManager},
    util::make_folder_from_revisions_pb,
};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub fn make_folder_ws_receiver(
    persistence: Arc<FlowyPersistence>,
    folder_manager: Arc<ServerFolderManager>,
) -> Arc<FolderWebSocketReceiver> {
    let (actor_msg_sender, rx) = tokio::sync::mpsc::channel(1000);
    let actor = FolderWebSocketActor::new(rx, folder_manager);
    tokio::task::spawn(actor.run());
    Arc::new(FolderWebSocketReceiver::new(persistence, actor_msg_sender))
}

pub struct FolderWebSocketReceiver {
    actor_msg_sender: mpsc::Sender<FolderWSActorMessage>,
    persistence: Arc<FlowyPersistence>,
}

impl FolderWebSocketReceiver {
    pub fn new(persistence: Arc<FlowyPersistence>, actor_msg_sender: mpsc::Sender<FolderWSActorMessage>) -> Self {
        Self {
            actor_msg_sender,
            persistence,
        }
    }
}

impl WebSocketReceiver for FolderWebSocketReceiver {
    fn receive(&self, data: WSClientData) {
        let (ret, rx) = oneshot::channel();
        let actor_msg_sender = self.actor_msg_sender.clone();
        let persistence = self.persistence.clone();

        actix_rt::spawn(async move {
            let msg = FolderWSActorMessage::ClientData {
                client_data: data,
                persistence,
                ret,
            };

            match actor_msg_sender.send(msg).await {
                Ok(_) => {}
                Err(e) => {
                    log::error!("[FolderWebSocketReceiver]: send message to actor failed: {}", e);
                }
            }
            match rx.await {
                Ok(_) => {}
                Err(e) => log::error!("[FolderWebSocketReceiver]: message ret failed {:?}", e),
            };
        });
    }
}

pub struct HttpFolderCloudPersistence(pub Arc<FolderRevisionKV>);
impl Debug for HttpFolderCloudPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str("HttpFolderCloudPersistence")
    }
}

impl FolderCloudPersistence for HttpFolderCloudPersistence {
    fn read_folder(&self, _user_id: &str, folder_id: &str) -> BoxResultFuture<FolderInfo, CollaborateError> {
        let folder_store = self.0.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let revisions = folder_store
                .get_revisions(&folder_id, None)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            match make_folder_from_revisions_pb(&folder_id, revisions)? {
                Some(folder_info) => Ok(folder_info),
                None => Err(CollaborateError::record_not_found().context(format!("{} not exist", folder_id))),
            }
        })
    }

    fn create_folder(
        &self,
        _user_id: &str,
        folder_id: &str,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<Option<FolderInfo>, CollaborateError> {
        let folder_store = self.0.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let folder_info = make_folder_from_revisions_pb(&folder_id, repeated_revision.clone())?;
            let revisions: Vec<RevisionPB> = repeated_revision.take_items().into();
            let _ = folder_store
                .set_revision(revisions)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            Ok(folder_info)
        })
    }

    fn save_folder_revisions(
        &self,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        let folder_store = self.0.clone();
        Box::pin(async move {
            let revisions: Vec<RevisionPB> = repeated_revision.take_items().into();
            let _ = folder_store
                .set_revision(revisions)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            Ok(())
        })
    }

    fn read_folder_revisions(
        &self,
        folder_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let folder_store = self.0.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let mut repeated_revision = folder_store
                .get_revisions(&folder_id, rev_ids)
                .await
                .map_err(|e| e.to_collaborate_error())?;
            let revisions: Vec<RevisionPB> = repeated_revision.take_items().into();
            Ok(revisions)
        })
    }

    fn reset_folder(
        &self,
        folder_id: &str,
        mut repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        let folder_store = self.0.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let _ = folder_store
                .transaction(|mut transaction| {
                    Box::pin(async move {
                        let _ = transaction.batch_delete_key_start_with(&folder_id).await?;
                        let items = revisions_to_key_value_items(repeated_revision.take_items().into())?;
                        let _ = transaction.batch_set(items).await?;
                        Ok(())
                    })
                })
                .await
                .map_err(|e| e.to_collaborate_error())?;
            Ok(())
        })
    }
}
