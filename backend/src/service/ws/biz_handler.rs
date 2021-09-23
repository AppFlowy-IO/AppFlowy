use bytes::Bytes;
use dashmap::{mapref::one::Ref, DashMap};
use flowy_ws::WsSource;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait WsBizHandler: Send + Sync {
    fn receive_data(&self, data: Bytes);
}

pub type BizHandler = Arc<RwLock<dyn WsBizHandler>>;

pub struct WsBizHandlers {
    inner: DashMap<WsSource, BizHandler>,
}

impl WsBizHandlers {
    pub fn new() -> Self {
        Self {
            inner: DashMap::new(),
        }
    }

    pub fn register(&self, source: WsSource, handler: BizHandler) {
        self.inner.insert(source, handler);
    }

    pub fn get(&self, source: &WsSource) -> Option<BizHandler> {
        match self.inner.get(source) {
            None => None,
            Some(handler) => Some(handler.clone()),
        }
    }
}
