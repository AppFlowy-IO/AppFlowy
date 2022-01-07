use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    entities::{
        doc::DocumentInfo,
        ws::{DocumentClientWSData, DocumentClientWSDataType},
    },
    errors::CollaborateError,
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    sync::*,
    util::repeated_revision_from_repeated_revision_pb,
};

use lib_infra::future::BoxResultFuture;
use lib_ws::{WSModule, WebSocketRawMessage};
use std::{
    convert::TryInto,
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
    pub async fn handle_client_data(
        &self,
        client_data: DocumentClientWSData,
    ) -> Option<mpsc::Receiver<WebSocketRawMessage>> {
        match client_data.ty {
            DocumentClientWSDataType::ClientPushRev => {
                let (tx, rx) = mpsc::channel(1);
                let user = Arc::new(MockDocUser {
                    user_id: "fake_user_id".to_owned(),
                    tx,
                });
                let pb_client_data: flowy_collaboration::protobuf::DocumentClientWSData =
                    client_data.try_into().unwrap();
                self.manager
                    .handle_client_revisions(user, pb_client_data)
                    .await
                    .unwrap();
                Some(rx)
            },
            DocumentClientWSDataType::ClientPing => {
                todo!()
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
