use crate::services::local::persistence::LocalServerDocumentPersistence;
use bytes::Bytes;
use flowy_collaboration::{
    entities::ws::{DocumentClientWSData, DocumentClientWSDataType},
    errors::CollaborateError,
    protobuf::DocumentClientWSData as DocumentClientWSDataPB,
    sync::*,
};
use lib_ws::{WSModule, WebSocketRawMessage};
use std::{convert::TryInto, fmt::Debug, sync::Arc};
use tokio::sync::{mpsc, mpsc::UnboundedSender};

pub struct LocalDocumentServer {
    pub doc_manager: Arc<ServerDocumentManager>,
    sender: mpsc::UnboundedSender<WebSocketRawMessage>,
    persistence: Arc<dyn ServerDocumentPersistence>,
}

impl LocalDocumentServer {
    pub fn new(sender: mpsc::UnboundedSender<WebSocketRawMessage>) -> Self {
        let persistence = Arc::new(LocalServerDocumentPersistence::default());
        let doc_manager = Arc::new(ServerDocumentManager::new(persistence.clone()));
        LocalDocumentServer {
            doc_manager,
            sender,
            persistence,
        }
    }

    pub async fn handle_client_data(
        &self,
        client_data: DocumentClientWSData,
        user_id: String,
    ) -> Result<(), CollaborateError> {
        tracing::trace!(
            "[LocalDocumentServer] receive: {}:{}-{:?} ",
            client_data.doc_id,
            client_data.id(),
            client_data.ty,
        );
        let user = Arc::new(LocalDocumentUser {
            user_id,
            ws_sender: self.sender.clone(),
            persistence: self.persistence.clone(),
        });
        let ty = client_data.ty.clone();
        let document_client_data: DocumentClientWSDataPB = client_data.try_into().unwrap();
        match ty {
            DocumentClientWSDataType::ClientPushRev => {
                let _ = self
                    .doc_manager
                    .handle_client_revisions(user, document_client_data)
                    .await?;
            },
            DocumentClientWSDataType::ClientPing => {
                let _ = self.doc_manager.handle_client_ping(user, document_client_data).await?;
            },
        }
        Ok(())
    }
}

#[derive(Debug)]
struct LocalDocumentUser {
    user_id: String,
    ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
    persistence: Arc<dyn ServerDocumentPersistence>,
}

impl RevisionUser for LocalDocumentUser {
    fn user_id(&self) -> String { self.user_id.clone() }

    fn receive(&self, resp: SyncResponse) {
        let sender = self.ws_sender.clone();
        let send_fn = |sender: UnboundedSender<WebSocketRawMessage>, msg: WebSocketRawMessage| match sender.send(msg) {
            Ok(_) => {},
            Err(e) => {
                tracing::error!("LocalDocumentUser send message failed: {}", e);
            },
        };

        tokio::spawn(async move {
            match resp {
                SyncResponse::Pull(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    send_fn(sender, msg);
                },
                SyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    send_fn(sender, msg);
                },
                SyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    send_fn(sender, msg);
                },
                SyncResponse::NewRevision(mut _repeated_revision) => {
                    // unimplemented!()
                },
            }
        });
    }
}
