use crate::local_server::LocalServer;
use crate::self_host::configuration::ClientServerConfiguration;

pub struct LocalServerContext {
  pub local_server: LocalServer,
}

pub fn build_server(_config: &ClientServerConfiguration) -> LocalServerContext {
  let local_server = LocalServer::new();
  LocalServerContext { local_server }
}
