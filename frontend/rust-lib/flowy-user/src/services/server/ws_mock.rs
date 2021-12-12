use crate::{
    errors::UserError,
    services::user::ws_manager::{FlowyWebSocket, FlowyWsSender},
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::{WsDataType, WsDocumentData};
use lib_infra::future::ResultFuture;
use lib_ws::{WsConnectState, WsMessage, WsMessageHandler, WsModule};
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
    fn start_connect(&self, _addr: String) -> ResultFuture<(), UserError> {
        let mut ws_receiver = self.ws_sender.subscribe();
        let cloned_ws = self.clone();
        tokio::spawn(async move {
            while let Ok(message) = ws_receiver.recv().await {
                let ws_data = WsDocumentData::try_from(Bytes::from(message.data.clone())).unwrap();
                match ws_data.ty {
                    WsDataType::Acked => {},
                    WsDataType::PushRev => {},
                    WsDataType::PullRev => {},
                    WsDataType::Conflict => {},
                    WsDataType::NewDocUser => {},
                }

                match cloned_ws.handlers.get(&message.module) {
                    None => log::error!("Can't find any handler for message: {:?}", message),
                    Some(handler) => handler.receive_message(message.clone()),
                }
            }
        });

        ResultFuture::new(async { Ok(()) })
    }

    fn conn_state_subscribe(&self) -> Receiver<WsConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> ResultFuture<(), UserError> { ResultFuture::new(async { Ok(()) }) }

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

impl FlowyWsSender for broadcast::Sender<WsMessage> {
    fn send(&self, msg: WsMessage) -> Result<(), UserError> {
        let _ = self.send(msg).unwrap();
        Ok(())
    }
}

pub(crate) struct LocalWebSocket {
    state_sender: broadcast::Sender<WsConnectState>,
    ws_sender: broadcast::Sender<WsMessage>,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        LocalWebSocket {
            state_sender,
            ws_sender,
        }
    }
}

impl FlowyWebSocket for Arc<LocalWebSocket> {
    fn start_connect(&self, _addr: String) -> ResultFuture<(), UserError> { ResultFuture::new(async { Ok(()) }) }

    fn conn_state_subscribe(&self) -> Receiver<WsConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> ResultFuture<(), UserError> { ResultFuture::new(async { Ok(()) }) }

    fn add_handler(&self, _handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError> { Ok(()) }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, UserError> { Ok(Arc::new(self.ws_sender.clone())) }
}
