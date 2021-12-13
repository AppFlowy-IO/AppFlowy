use crate::{
    errors::UserError,
    services::user::ws_manager::{FlowyWebSocket, FlowyWsSender},
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::{
    core::sync::{ServerDocManager, ServerDocPersistence},
    entities::{
        doc::{Doc, NewDocUser},
        ws::{WsDataType, WsDocumentData},
    },
    errors::CollaborateError,
};
use lazy_static::lazy_static;
use lib_infra::future::{FutureResult, FutureResultSend};
use lib_ot::{revision::Revision, rich_text::RichTextDelta};
use lib_ws::{WsConnectState, WsMessage, WsMessageHandler, WsModule};
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, broadcast::Receiver};

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
    fn start_connect(&self, _addr: String) -> FutureResult<(), UserError> {
        let mut ws_receiver = self.ws_sender.subscribe();
        let cloned_ws = self.clone();
        tokio::spawn(async move {
            while let Ok(message) = ws_receiver.recv().await {
                let ws_data = WsDocumentData::try_from(Bytes::from(message.data.clone())).unwrap();
                match DOC_SERVER.handle_ws_data(ws_data).await {
                    None => {},
                    Some(new_ws_message) => match cloned_ws.handlers.get(&new_ws_message.module) {
                        None => log::error!("Can't find any handler for message: {:?}", new_ws_message),
                        Some(handler) => handler.receive_message(new_ws_message.clone()),
                    },
                }
            }
        });

        FutureResult::new(async { Ok(()) })
    }

    fn conn_state_subscribe(&self) -> Receiver<WsConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), UserError> { FutureResult::new(async { Ok(()) }) }

    fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            log::error!("WsSource's {:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, UserError> { Ok(Arc::new(self.ws_sender.clone())) }
}

lazy_static! {
    static ref DOC_SERVER: Arc<MockDocServer> = Arc::new(MockDocServer::default());
}

struct MockDocServer {
    pub manager: Arc<ServerDocManager>,
}

impl std::default::Default for MockDocServer {
    fn default() -> Self {
        let manager = Arc::new(ServerDocManager::new(Arc::new(MockDocServerPersistence {})));
        MockDocServer { manager }
    }
}

impl MockDocServer {
    async fn handle_ws_data(&self, ws_data: WsDocumentData) -> Option<WsMessage> {
        let bytes = Bytes::from(ws_data.data);
        match ws_data.ty {
            WsDataType::Acked => {},
            WsDataType::PushRev => {
                let revision = Revision::try_from(bytes).unwrap();
                log::info!("{:?}", revision);
            },
            WsDataType::PullRev => {},
            WsDataType::Conflict => {},
            WsDataType::NewDocUser => {
                let new_doc_user = NewDocUser::try_from(bytes).unwrap();
                log::info!("{:?}", new_doc_user);
                // NewDocUser
            },
        }
        None
    }
}

struct MockDocServerPersistence {}

impl ServerDocPersistence for MockDocServerPersistence {
    fn update_doc(&self, doc_id: &str, rev_id: i64, delta: RichTextDelta) -> FutureResultSend<(), CollaborateError> {
        unimplemented!()
    }

    fn read_doc(&self, doc_id: &str) -> FutureResultSend<Doc, CollaborateError> { unimplemented!() }
}
