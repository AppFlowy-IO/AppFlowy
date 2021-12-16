use crate::web_socket::WsClientData;
use lib_ws::WSModule;
use std::{collections::HashMap, sync::Arc};

pub trait WsBizHandler: Send + Sync {
    fn receive(&self, data: WsClientData);
}

pub type BizHandler = Arc<dyn WsBizHandler>;
pub struct WsBizHandlers {
    inner: HashMap<WSModule, BizHandler>,
}

impl std::default::Default for WsBizHandlers {
    fn default() -> Self { Self { inner: HashMap::new() } }
}

impl WsBizHandlers {
    pub fn new() -> Self { WsBizHandlers::default() }

    pub fn register(&mut self, source: WSModule, handler: BizHandler) { self.inner.insert(source, handler); }

    pub fn get(&self, source: &WSModule) -> Option<BizHandler> { self.inner.get(source).cloned() }
}
