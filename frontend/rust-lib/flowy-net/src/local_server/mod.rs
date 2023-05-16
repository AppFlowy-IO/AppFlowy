use tokio::sync::{broadcast, mpsc};

use flowy_client_network_config::ClientServerConfiguration;
pub use server::*;

mod server;

pub struct LocalServerContext {
  pub local_server: LocalServer,
}

pub fn build_server(_config: &ClientServerConfiguration) -> LocalServerContext {
  let local_server = LocalServer::new();
  LocalServerContext { local_server }
}
