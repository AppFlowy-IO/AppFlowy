use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    entities::{
        doc::DocumentInfo,
        ws::{DocumentClientWSData, DocumentClientWSDataType},
    },
    errors::CollaborateError,
    protobuf::{
        DocumentClientWSData as DocumentClientWSDataPB,
        RepeatedRevision as RepeatedRevisionPB,
        Revision as RevisionPB,
    },
    sync::*,
    util::repeated_revision_from_repeated_revision_pb,
};
use lib_infra::future::BoxResultFuture;
use lib_ws::{WSMessageReceiver, WSModule, WebSocketRawMessage};
use std::{
    convert::TryInto,
    fmt::{Debug, Formatter},
    sync::Arc,
};
use tokio::sync::mpsc;

pub(crate) fn spawn_server(receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>) -> Arc<LocalDocumentServer> {
    let (server_tx, mut server_rx) = mpsc::unbounded_channel();
    let server = Arc::new(LocalDocumentServer::new(server_tx));
    tokio::spawn(async move {
        while let Some(message) = server_rx.recv().await {
            match receivers.get(&message.module) {
                None => tracing::error!("Can't find any handler for message: {:?}", message),
                Some(handler) => handler.receive_message(message.clone()),
            }
        }
    });
    server
}

pub struct LocalDocumentServer {
    pub doc_manager: Arc<ServerDocumentManager>,
    sender: mpsc::UnboundedSender<WebSocketRawMessage>,
}

impl LocalDocumentServer {
    pub fn new(sender: mpsc::UnboundedSender<WebSocketRawMessage>) -> Self {
        let persistence = Arc::new(LocalDocServerPersistence::default());
        let doc_manager = Arc::new(ServerDocumentManager::new(persistence));
        LocalDocumentServer { doc_manager, sender }
    }

    pub async fn handle_client_data(&self, client_data: DocumentClientWSData) -> Result<(), CollaborateError> {
        tracing::debug!(
            "[LocalDocumentServer] receive client data: {}:{:?} ",
            client_data.doc_id,
            client_data.ty
        );
        let user = Arc::new(LocalDocumentUser {
            user_id: "fake_user_id".to_owned(),
            ws_sender: self.sender.clone(),
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

struct LocalDocServerPersistence {
    inner: Arc<DashMap<String, DocumentInfo>>,
}

impl Debug for LocalDocServerPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("MockDocServerPersistence") }
}

impl std::default::Default for LocalDocServerPersistence {
    fn default() -> Self {
        LocalDocServerPersistence {
            inner: Arc::new(DashMap::new()),
        }
    }
}

impl DocumentPersistence for LocalDocServerPersistence {
    fn read_doc(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let inner = self.inner.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            match inner.get(&doc_id) {
                None => {
                    //
                    Err(CollaborateError::record_not_found())
                },
                Some(val) => {
                    //
                    Ok(val.value().clone())
                },
            }
        })
    }

    fn create_doc(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let repeated_revision = repeated_revision_from_repeated_revision_pb(repeated_revision)?;
            DocumentInfo::from_revisions(&doc_id, repeated_revision.into_inner())
        })
    }

    fn get_revisions(&self, _doc_id: &str, _rev_ids: Vec<i64>) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        Box::pin(async move { Ok(vec![]) })
    }

    fn get_doc_revisions(&self, _doc_id: &str) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        unimplemented!()
    }

    fn reset_document(&self, _doc_id: &str, _revisions: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
        unimplemented!()
    }
}

#[derive(Debug)]
struct LocalDocumentUser {
    user_id: String,
    ws_sender: mpsc::UnboundedSender<WebSocketRawMessage>,
}

impl RevisionUser for LocalDocumentUser {
    fn user_id(&self) -> String { self.user_id.clone() }

    fn receive(&self, resp: SyncResponse) {
        let sender = self.ws_sender.clone();
        tokio::spawn(async move {
            match resp {
                SyncResponse::Pull(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).unwrap();
                },
                SyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).unwrap();
                },
                SyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).unwrap();
                },
                SyncResponse::NewRevision(_) => {
                    // unimplemented!()
                },
            }
        });
    }
}
