use crate::http_server::self_host::configuration::ClientServerConfiguration;
use crate::local_server::LocalServer;

pub struct LocalServerContext {
  pub local_server: LocalServer,
}

pub fn build_server(_config: &ClientServerConfiguration) -> LocalServerContext {
  let local_server = LocalServer::new();
  LocalServerContext { local_server }
}
