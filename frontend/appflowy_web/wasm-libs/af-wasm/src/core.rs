use crate::integrate::server::ServerProviderWASM;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use lib_dispatch::prelude::AFPluginDispatcher;
use lib_dispatch::runtime::AFPluginRuntime;
use std::rc::Rc;
use std::sync::Arc;

pub struct AppFlowyWASMCore {
  pub event_dispatcher: Rc<AFPluginDispatcher>,
}

impl AppFlowyWASMCore {
  pub fn new(device_id: &str) -> Self {
    let runtime = Arc::new(AFPluginRuntime::new().unwrap());
    let server_provider = Arc::new(ServerProviderWASM::new(device_id));

    let event_dispatcher = Rc::new(AFPluginDispatcher::new(runtime, vec![]));
    let collab_builder = Arc::new(AppFlowyCollabBuilder::new(
      server_provider.clone(),
      device_id.to_string(),
    ));
    Self { event_dispatcher }
  }
}
