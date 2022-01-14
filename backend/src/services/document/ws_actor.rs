use crate::{
    context::FlowyPersistence,
    services::web_socket::{entities::Socket, WSClientData, WSUser, WebSocketMessage},
    util::serde_ext::{md5, parse_from_bytes},
};
use actix_rt::task::spawn_blocking;
use async_stream::stream;
use backend_service::errors::{internal_error, Result, ServerError};

use flowy_collaboration::{
    protobuf::{
        ClientRevisionWSData as ClientRevisionWSDataPB,
        ClientRevisionWSDataType as ClientRevisionWSDataTypePB,
        Revision as RevisionPB,
    },
    server_document::{RevisionUser, ServerDocumentManager, SyncResponse},
};
use futures::stream::StreamExt;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

pub enum WSActorMessage {
    ClientData {
        client_data: WSClientData,
        persistence: Arc<FlowyPersistence>,
        ret: oneshot::Sender<Result<()>>,
    },
}

pub struct DocumentWebSocketActor {
    receiver: Option<mpsc::Receiver<WSActorMessage>>,
    doc_manager: Arc<ServerDocumentManager>,
}

impl DocumentWebSocketActor {
    pub fn new(receiver: mpsc::Receiver<WSActorMessage>, manager: Arc<ServerDocumentManager>) -> Self {
        Self {
            receiver: Some(receiver),
            doc_manager: manager,
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self
            .receiver
            .take()
            .expect("DocActor's receiver should only take one time");

        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };

        stream.for_each(|msg| self.handle_message(msg)).await;
    }

    async fn handle_message(&self, msg: WSActorMessage) {
        match msg {
            WSActorMessage::ClientData {
                client_data,
                persistence: _,
                ret,
            } => {
                let _ = ret.send(self.handle_client_data(client_data).await);
            },
        }
    }

    async fn handle_client_data(&self, client_data: WSClientData) -> Result<()> {
        let WSClientData { user, socket, data } = client_data;
        let document_client_data = spawn_blocking(move || parse_from_bytes::<ClientRevisionWSDataPB>(&data))
            .await
            .map_err(internal_error)??;

        tracing::debug!(
            "[DocumentWebSocketActor]: receive: {}:{}, {:?}",
            document_client_data.object_id,
            document_client_data.data_id,
            document_client_data.ty
        );

        let user = Arc::new(HttpDocumentUser { user, socket });

        match &document_client_data.ty {
            ClientRevisionWSDataTypePB::ClientPushRev => {
                let _ = self
                    .doc_manager
                    .handle_client_revisions(user, document_client_data)
                    .await
                    .map_err(internal_error)?;
            },
            ClientRevisionWSDataTypePB::ClientPing => {
                let _ = self
                    .doc_manager
                    .handle_client_ping(user, document_client_data)
                    .await
                    .map_err(internal_error)?;
            },
        }

        Ok(())
    }
}

#[allow(dead_code)]
fn verify_md5(revision: &RevisionPB) -> Result<()> {
    if md5(&revision.delta_data) != revision.md5 {
        return Err(ServerError::internal().context("RevisionPB md5 not match"));
    }
    Ok(())
}

#[derive(Clone)]
pub struct HttpDocumentUser {
    pub user: Arc<WSUser>,
    pub(crate) socket: Socket,
}

impl std::fmt::Debug for HttpDocumentUser {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("ServerDocUser")
            .field("user", &self.user)
            .field("socket", &self.socket)
            .finish()
    }
}

impl RevisionUser for HttpDocumentUser {
    fn user_id(&self) -> String { self.user.id().to_string() }

    fn receive(&self, resp: SyncResponse) {
        let result = match resp {
            SyncResponse::Pull(data) => {
                let msg: WebSocketMessage = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Push(data) => {
                let msg: WebSocketMessage = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Ack(data) => {
                let msg: WebSocketMessage = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
        };

        match result {
            Ok(_) => {},
            Err(e) => log::error!("[ServerDocUser]: {}", e),
        }
    }
}
