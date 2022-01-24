use crate::{
    context::FlowyPersistence,
    services::web_socket::{entities::Socket, revision_data_to_ws_message, WSClientData, WSUser, WebSocketMessage},
    util::serde_ext::parse_from_bytes,
};
use actix_rt::task::spawn_blocking;
use async_stream::stream;
use backend_service::errors::{internal_error, Result};

use flowy_collaboration::{
    protobuf::{
        ClientRevisionWSData as ClientRevisionWSDataPB, ClientRevisionWSDataType as ClientRevisionWSDataTypePB,
    },
    server_folder::ServerFolderManager,
    synchronizer::{RevisionSyncResponse, RevisionUser},
};
use futures::stream::StreamExt;
use lib_ws::WSChannel;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub enum FolderWSActorMessage {
    ClientData {
        client_data: WSClientData,
        persistence: Arc<FlowyPersistence>,
        ret: oneshot::Sender<Result<()>>,
    },
}

pub struct FolderWebSocketActor {
    actor_msg_receiver: Option<mpsc::Receiver<FolderWSActorMessage>>,
    folder_manager: Arc<ServerFolderManager>,
}

impl FolderWebSocketActor {
    pub fn new(receiver: mpsc::Receiver<FolderWSActorMessage>, folder_manager: Arc<ServerFolderManager>) -> Self {
        Self {
            actor_msg_receiver: Some(receiver),
            folder_manager,
        }
    }

    pub async fn run(mut self) {
        let mut actor_msg_receiver = self
            .actor_msg_receiver
            .take()
            .expect("FolderWebSocketActor's receiver should only take one time");
        let stream = stream! {
            loop {
                match actor_msg_receiver.recv().await {
                    Some(msg) => yield msg,
                    None => {
                        break
                    },
                }
            }
        };
        stream.for_each(|msg| self.handle_message(msg)).await;
    }

    async fn handle_message(&self, msg: FolderWSActorMessage) {
        match msg {
            FolderWSActorMessage::ClientData {
                client_data,
                persistence: _,
                ret,
            } => {
                let _ = ret.send(self.handle_folder_data(client_data).await);
            }
        }
    }

    async fn handle_folder_data(&self, client_data: WSClientData) -> Result<()> {
        let WSClientData { user, socket, data } = client_data;
        let folder_client_data = spawn_blocking(move || parse_from_bytes::<ClientRevisionWSDataPB>(&data))
            .await
            .map_err(internal_error)??;

        tracing::debug!(
            "[FolderWebSocketActor]: receive: {}:{}, {:?}",
            folder_client_data.object_id,
            folder_client_data.data_id,
            folder_client_data.ty
        );

        let user = Arc::new(FolderRevisionUser { user, socket });
        match &folder_client_data.ty {
            ClientRevisionWSDataTypePB::ClientPushRev => {
                let _ = self
                    .folder_manager
                    .handle_client_revisions(user, folder_client_data)
                    .await
                    .map_err(internal_error)?;
            }
            ClientRevisionWSDataTypePB::ClientPing => {
                let _ = self
                    .folder_manager
                    .handle_client_ping(user, folder_client_data)
                    .await
                    .map_err(internal_error)?;
            }
        }
        Ok(())
    }
}

#[derive(Clone)]
pub struct FolderRevisionUser {
    pub user: Arc<WSUser>,
    pub(crate) socket: Socket,
}

impl std::fmt::Debug for FolderRevisionUser {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("FolderRevisionUser")
            .field("user", &self.user)
            .field("socket", &self.socket)
            .finish()
    }
}

impl RevisionUser for FolderRevisionUser {
    fn user_id(&self) -> String {
        self.user.id().to_string()
    }

    fn receive(&self, resp: RevisionSyncResponse) {
        let result = match resp {
            RevisionSyncResponse::Pull(data) => {
                let msg: WebSocketMessage = revision_data_to_ws_message(data, WSChannel::Folder);
                self.socket.try_send(msg).map_err(internal_error)
            }
            RevisionSyncResponse::Push(data) => {
                let msg: WebSocketMessage = revision_data_to_ws_message(data, WSChannel::Folder);
                self.socket.try_send(msg).map_err(internal_error)
            }
            RevisionSyncResponse::Ack(data) => {
                let msg: WebSocketMessage = revision_data_to_ws_message(data, WSChannel::Folder);
                self.socket.try_send(msg).map_err(internal_error)
            }
        };

        match result {
            Ok(_) => {}
            Err(e) => log::error!("[FolderRevisionUser]: {}", e),
        }
    }
}
