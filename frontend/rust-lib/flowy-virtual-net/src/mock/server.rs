use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{entities::prelude::*, errors::CollaborateError, sync::*};
use flowy_net::services::ws::*;
use lib_infra::future::FutureResultSend;
use lib_ws::{WSModule, WebSocketRawMessage};
use std::{
    convert::{TryFrom, TryInto},
    fmt::{Debug, Formatter},
    sync::Arc,
};
use tokio::sync::mpsc;

pub struct MockDocServer {
    pub manager: Arc<ServerDocumentManager>,
}

impl std::default::Default for MockDocServer {
    fn default() -> Self {
        let persistence = Arc::new(MockDocServerPersistence::default());
        let manager = Arc::new(ServerDocumentManager::new(persistence));
        MockDocServer { manager }
    }
}

impl MockDocServer {
    pub async fn handle_ws_data(&self, ws_data: DocumentClientWSData) -> Option<mpsc::Receiver<WebSocketRawMessage>> {
        let bytes = Bytes::from(ws_data.data);
        match ws_data.ty {
            DocumentClientWSDataType::ClientPushRev => {
                let revisions = RepeatedRevision::try_from(bytes).unwrap().into_inner();
                if revisions.is_empty() {
                    return None;
                }
                let first_revision = revisions.first().unwrap();
                let (tx, rx) = mpsc::channel(1);
                let user = Arc::new(MockDocUser {
                    user_id: first_revision.user_id.clone(),
                    tx,
                });
                self.manager.apply_revisions(user, revisions).await.unwrap();
                Some(rx)
            },
        }
    }
}

struct MockDocServerPersistence {
    inner: Arc<DashMap<String, DocumentInfo>>,
}

impl Debug for MockDocServerPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("MockDocServerPersistence") }
}

impl std::default::Default for MockDocServerPersistence {
    fn default() -> Self {
        MockDocServerPersistence {
            inner: Arc::new(DashMap::new()),
        }
    }
}

impl DocumentPersistence for MockDocServerPersistence {
    fn read_doc(&self, doc_id: &str) -> FutureResultSend<DocumentInfo, CollaborateError> {
        let inner = self.inner.clone();
        let doc_id = doc_id.to_owned();
        FutureResultSend::new(async move {
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

    fn create_doc(&self, revision: Revision) -> FutureResultSend<DocumentInfo, CollaborateError> {
        FutureResultSend::new(async move {
            let document_info: DocumentInfo = revision.try_into().unwrap();
            Ok(document_info)
        })
    }

    fn get_revisions(&self, _doc_id: &str, _rev_ids: Vec<i64>) -> FutureResultSend<Vec<Revision>, CollaborateError> {
        unimplemented!()
    }
}

#[derive(Debug)]
struct MockDocUser {
    user_id: String,
    tx: mpsc::Sender<WebSocketRawMessage>,
}

impl RevisionUser for MockDocUser {
    fn user_id(&self) -> String { self.user_id.clone() }

    fn receive(&self, resp: SyncResponse) {
        let sender = self.tx.clone();
        tokio::spawn(async move {
            match resp {
                SyncResponse::Pull(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WebSocketRawMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::NewRevision(_) => {
                    // unimplemented!()
                },
            }
        });
    }
}
