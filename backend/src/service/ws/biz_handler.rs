use crate::service::ws::WsClientData;
use bytes::Bytes;
use flowy_ws::WsModule;
use std::{collections::HashMap, sync::Arc};

pub trait WsBizHandler: Send + Sync {
    fn receive_data(&self, client_data: WsClientData);
}

pub type BizHandler = Arc<dyn WsBizHandler>;
pub struct WsBizHandlers {
    inner: HashMap<WsModule, BizHandler>,
}

impl WsBizHandlers {
    pub fn new() -> Self {
        Self {
            inner: HashMap::new(),
        }
    }

    pub fn register(&mut self, source: WsModule, handler: BizHandler) {
        self.inner.insert(source, handler);
    }

    pub fn get(&self, source: &WsModule) -> Option<BizHandler> {
        match self.inner.get(source) {
            None => None,
            Some(handler) => Some(handler.clone()),
        }
    }
}
