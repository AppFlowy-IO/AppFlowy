use crate::services::ws::{FlowyError, FlowyWebSocket, FlowyWsSender, WSConnectState, WSMessage, WSMessageReceiver};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    core::sync::{DocumentPersistence, RevisionUser, ServerDocumentManager, SyncResponse},
    entities::{
        doc::DocumentInfo,
        revision::{RepeatedRevision, Revision},
        ws::{DocumentWSData, DocumentWSDataBuilder, DocumentWSDataType, NewDocumentUser},
    },
    errors::CollaborateError,
};
use lazy_static::lazy_static;
use lib_infra::future::{FutureResult, FutureResultSend};
use lib_ws::WSModule;
use parking_lot::RwLock;
use std::{
    convert::{TryFrom, TryInto},
    fmt::{Debug, Formatter},
    sync::Arc,
};
use tokio::sync::{broadcast, broadcast::Receiver, mpsc};

pub struct MockWebSocket {
    handlers: DashMap<WSModule, Arc<dyn WSMessageReceiver>>,
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: broadcast::Sender<WSMessage>,
    is_stop: RwLock<bool>,
}

impl std::default::Default for MockWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        MockWebSocket {
            handlers: DashMap::new(),
            state_sender,
            ws_sender,
            is_stop: RwLock::new(false),
        }
    }
}

impl MockWebSocket {
    pub fn new() -> MockWebSocket { MockWebSocket::default() }
}

impl FlowyWebSocket for Arc<MockWebSocket> {
    fn start_connect(&self, _addr: String) -> FutureResult<(), FlowyError> {
        *self.is_stop.write() = false;

        let mut ws_receiver = self.ws_sender.subscribe();
        let cloned_ws = self.clone();
        tokio::spawn(async move {
            while let Ok(message) = ws_receiver.recv().await {
                if *cloned_ws.is_stop.read() {
                    // do nothing
                } else {
                    let ws_data = DocumentWSData::try_from(Bytes::from(message.data.clone())).unwrap();
                    let mut rx = DOC_SERVER.handle_ws_data(ws_data).await;
                    let new_ws_message = rx.recv().await.unwrap();
                    match cloned_ws.handlers.get(&new_ws_message.module) {
                        None => tracing::error!("Can't find any handler for message: {:?}", new_ws_message),
                        Some(handler) => handler.receive_message(new_ws_message.clone()),
                    }
                }
            }
        });

        FutureResult::new(async { Ok(()) })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> {
        *self.is_stop.write() = true;
        FutureResult::new(async { Ok(()) })
    }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
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
    async fn handle_ws_data(&self, ws_data: DocumentWSData) -> mpsc::Receiver<WSMessage> {
        let bytes = Bytes::from(ws_data.data);
        match ws_data.ty {
            DocumentWSDataType::Ack => {
                unimplemented!()
            },
            DocumentWSDataType::PushRev => {
                let revisions = RepeatedRevision::try_from(bytes).unwrap().into_inner();
                let (tx, rx) = mpsc::channel(1);
                let user = MockDocUser {
                    user_id: revision.user_id.clone(),
                    tx,
                };
                self.manager.apply_revisions(user, revisions).await.unwrap();

                rx
            },
            DocumentWSDataType::PullRev => {
                unimplemented!()
            },
            DocumentWSDataType::UserConnect => {
                let new_user = NewDocumentUser::try_from(bytes).unwrap();
                let (tx, rx) = mpsc::channel(1);
                let data = DocumentWSDataBuilder::build_ack_message(&new_user.doc_id, &ws_data.id);
                let user = Arc::new(MockDocUser {
                    user_id: new_user.user_id,
                    tx,
                }) as Arc<dyn RevisionUser>;

                user.receive(SyncResponse::Ack(data));
                rx
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
    tx: mpsc::Sender<WSMessage>,
}

impl RevisionUser for MockDocUser {
    fn user_id(&self) -> String { self.user_id.clone() }

    fn receive(&self, resp: SyncResponse) {
        let sender = self.tx.clone();
        tokio::spawn(async move {
            match resp {
                SyncResponse::Pull(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WSMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Push(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WSMessage {
                        module: WSModule::Doc,
                        data: bytes.to_vec(),
                    };
                    sender.send(msg).await.unwrap();
                },
                SyncResponse::Ack(data) => {
                    let bytes: Bytes = data.try_into().unwrap();
                    let msg = WSMessage {
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
