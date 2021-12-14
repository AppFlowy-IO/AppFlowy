use crate::services::ws::{FlowyError, FlowyWebSocket, FlowyWsSender, WsConnectState, WsMessage, WsMessageHandler};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    core::sync::{RevisionUser, ServerDocManager, ServerDocPersistence, SyncResponse},
    entities::{
        doc::Doc,
        ws::{WsDataType, WsDocumentData},
    },
    errors::CollaborateError,
    Revision,
    RichTextDelta,
};
use lazy_static::lazy_static;
use lib_infra::future::{FutureResult, FutureResultSend};
use lib_ws::WsModule;
use std::{
    convert::{TryFrom, TryInto},
    sync::Arc,
};
use tokio::sync::{broadcast, broadcast::Receiver, mpsc};

pub struct MockWebSocket {
    handlers: DashMap<WsModule, Arc<dyn WsMessageHandler>>,
    state_sender: broadcast::Sender<WsConnectState>,
    ws_sender: broadcast::Sender<WsMessage>,
}

impl std::default::Default for MockWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        MockWebSocket {
            handlers: DashMap::new(),
            state_sender,
            ws_sender,
        }
    }
}

impl MockWebSocket {
    pub fn new() -> MockWebSocket { MockWebSocket::default() }
}

impl FlowyWebSocket for Arc<MockWebSocket> {
    fn start_connect(&self, _addr: String) -> FutureResult<(), FlowyError> {
        let mut ws_receiver = self.ws_sender.subscribe();
        let cloned_ws = self.clone();
        tokio::spawn(async move {
            while let Ok(message) = ws_receiver.recv().await {
                let ws_data = WsDocumentData::try_from(Bytes::from(message.data.clone())).unwrap();
                let mut rx = DOC_SERVER.handle_ws_data(ws_data).await;
                let new_ws_message = rx.recv().await.unwrap();
                match cloned_ws.handlers.get(&new_ws_message.module) {
                    None => tracing::error!("Can't find any handler for message: {:?}", new_ws_message),
                    Some(handler) => handler.receive_message(new_ws_message.clone()),
                }
            }
        });

        FutureResult::new(async { Ok(()) })
    }

    fn conn_state_subscribe(&self) -> Receiver<WsConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), FlowyError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            tracing::error!("WsSource's {:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
}

lazy_static! {
    static ref DOC_SERVER: Arc<MockDocServer> = Arc::new(MockDocServer::default());
}

struct MockDocServer {
    pub manager: Arc<ServerDocManager>,
}

impl std::default::Default for MockDocServer {
    fn default() -> Self {
        let persistence = Arc::new(MockDocServerPersistence::default());
        let manager = Arc::new(ServerDocManager::new(persistence));
        MockDocServer { manager }
    }
}

impl MockDocServer {
    async fn handle_ws_data(&self, ws_data: WsDocumentData) -> mpsc::Receiver<WsMessage> {
        let bytes = Bytes::from(ws_data.data);
        match ws_data.ty {
            WsDataType::Acked => {
                unimplemented!()
            },
            WsDataType::PushRev => {
                let revision = Revision::try_from(bytes).unwrap();
                let handler = match self.manager.get(&revision.doc_id).await {
                    None => self.manager.create_doc(revision.clone()).await.unwrap(),
                    Some(handler) => handler,
                };

                let (tx, rx) = mpsc::channel(1);
                let user = MockDocUser {
                    user_id: revision.user_id.clone(),
                    tx,
                };
                handler.apply_revision(Arc::new(user), revision).await.unwrap();
                rx
            },
            WsDataType::PullRev => {
                unimplemented!()
            },
            WsDataType::Conflict => {
                unimplemented!()
            },
        }
    }
}

struct MockDocServerPersistence {
    inner: Arc<DashMap<String, Doc>>,
}

impl std::default::Default for MockDocServerPersistence {
    fn default() -> Self {
        MockDocServerPersistence {
            inner: Arc::new(DashMap::new()),
        }
    }
}

impl ServerDocPersistence for MockDocServerPersistence {
    fn update_doc(&self, _doc_id: &str, _rev_id: i64, _delta: RichTextDelta) -> FutureResultSend<(), CollaborateError> {
        unimplemented!()
    }

    fn read_doc(&self, doc_id: &str) -> FutureResultSend<Doc, CollaborateError> {
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

    fn create_doc(&self, revision: Revision) -> FutureResultSend<Doc, CollaborateError> {
        FutureResultSend::new(async move {
            let doc: Doc = revision.try_into().unwrap();
            Ok(doc)
        })
    }
}

#[derive(Debug)]
struct MockDocUser {
    user_id: String,
    tx: mpsc::Sender<WsMessage>,
}

impl RevisionUser for MockDocUser {
    fn user_id(&self) -> String { self.user_id.clone() }

    fn recv(&self, resp: SyncResponse) {
        let sender = self.tx.clone();
        tokio::spawn(async move {
            match resp {
                SyncResponse::Pull(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WsMessage {
                        module: WsModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WsMessage {
                        module: WsModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WsMessage {
                        module: WsModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::NewRevision {
                    rev_id: _,
                    doc_id: _,
                    doc_json: _,
                } => {
                    // unimplemented!()
                },
            }
        });
    }
}
