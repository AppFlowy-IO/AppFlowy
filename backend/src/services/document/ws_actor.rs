use crate::{
    services::web_socket::{entities::Socket, WSClientData, WSMessageAdaptor, WSUser},
    util::serde_ext::{md5, parse_from_bytes},
};
use actix_rt::task::spawn_blocking;

use crate::context::FlowyPersistence;
use async_stream::stream;
use backend_service::errors::{internal_error, Result, ServerError};
use flowy_collaboration::{
    core::sync::{RevisionUser, ServerDocumentManager, SyncResponse},
    protobuf::{DocumentWSData, DocumentWSDataType, NewDocumentUser, Revision},
};
use futures::stream::StreamExt;

use std::{convert::TryInto, sync::Arc};
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
                persistence,
                ret,
            } => {
                let _ = ret.send(self.handle_client_data(client_data, persistence).await);
            },
        }
    }

    async fn handle_client_data(&self, client_data: WSClientData, persistence: Arc<FlowyPersistence>) -> Result<()> {
        let WSClientData { user, socket, data } = client_data;
        let document_data = spawn_blocking(move || {
            let document_data: DocumentWSData = parse_from_bytes(&data)?;
            Result::Ok(document_data)
        })
        .await
        .map_err(internal_error)??;

        tracing::debug!(
            "[HTTP_SERVER_WS]: receive client data: {}:{}, {:?}",
            document_data.doc_id,
            document_data.id,
            document_data.ty
        );

        let user = Arc::new(ServerDocUser {
            user,
            socket,
            persistence,
        });
        let result = match &document_data.ty {
            DocumentWSDataType::Ack => Ok(()),
            DocumentWSDataType::PushRev => self.handle_pushed_rev(user, document_data.data).await,
            DocumentWSDataType::PullRev => Ok(()),
            DocumentWSDataType::UserConnect => self.handle_user_connect(user, document_data).await,
        };
        match result {
            Ok(_) => {},
            Err(e) => {
                tracing::error!("[HTTP_SERVER_WS]: process client data error {:?}", e);
            },
        }

        Ok(())
    }

    async fn handle_user_connect(&self, user: Arc<ServerDocUser>, document_data: DocumentWSData) -> Result<()> {
        let mut new_user = spawn_blocking(move || parse_from_bytes::<NewDocumentUser>(&document_data.data))
            .await
            .map_err(internal_error)??;

        let revision_pb = spawn_blocking(move || parse_from_bytes::<Revision>(&new_user.take_revision_data()))
            .await
            .map_err(internal_error)??;
        let _ = self.handle_revision(user, revision_pb).await?;
        Ok(())
    }

    async fn handle_pushed_rev(&self, user: Arc<ServerDocUser>, data: Vec<u8>) -> Result<()> {
        let revision_pb = spawn_blocking(move || {
            let revision: Revision = parse_from_bytes(&data)?;
            // let _ = verify_md5(&revision)?;
            Result::Ok(revision)
        })
        .await
        .map_err(internal_error)??;
        self.handle_revision(user, revision_pb).await
    }

    async fn handle_revision(&self, user: Arc<ServerDocUser>, mut revision: Revision) -> Result<()> {
        let revision: flowy_collaboration::entities::revision::Revision =
            (&mut revision).try_into().map_err(internal_error)?;
        // Create the document if it doesn't exist
        let handler = match self.doc_manager.get(&revision.doc_id).await {
            None => self
                .doc_manager
                .create_doc(revision.clone())
                .await
                .map_err(internal_error)?,
            Some(handler) => handler,
        };

        handler.apply_revision(user, revision).await.map_err(internal_error)?;
        Ok(())
    }
}

#[allow(dead_code)]
fn verify_md5(revision: &Revision) -> Result<()> {
    if md5(&revision.delta_data) != revision.md5 {
        return Err(ServerError::internal().context("Revision md5 not match"));
    }
    Ok(())
}

#[derive(Clone)]
pub struct ServerDocUser {
    pub user: Arc<WSUser>,
    pub(crate) socket: Socket,
    pub persistence: Arc<FlowyPersistence>,
}

impl std::fmt::Debug for ServerDocUser {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.debug_struct("ServerDocUser")
            .field("user", &self.user)
            .field("socket", &self.socket)
            .finish()
    }
}

impl RevisionUser for ServerDocUser {
    fn user_id(&self) -> String { self.user.id().to_string() }

    fn receive(&self, resp: SyncResponse) {
        let result = match resp {
            SyncResponse::Pull(data) => {
                let msg: WSMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Push(data) => {
                let msg: WSMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Ack(data) => {
                let msg: WSMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::NewRevision(revision) => {
                let kv_store = self.persistence.kv_store();
                tokio::task::spawn(async move {
                    let revision: flowy_collaboration::protobuf::Revision = revision.try_into().unwrap();
                    match kv_store.batch_set_revision(vec![revision]).await {
                        Ok(_) => {},
                        Err(e) => log::error!("{}", e),
                    }
                });
                Ok(())
            },
        };

        match result {
            Ok(_) => {},
            Err(e) => log::error!("[ServerDocUser]: {}", e),
        }
    }
}
