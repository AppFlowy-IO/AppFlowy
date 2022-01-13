use backend_service::configuration::ClientServerConfiguration;
use tokio::sync::{broadcast, mpsc};

mod persistence;
mod server;
mod ws;

pub use server::*;
pub use ws::*;

pub struct LocalServerContext {
    pub local_ws: LocalWebSocket,
    pub local_server: LocalServer,
}

pub fn build_server(_config: &ClientServerConfiguration) -> LocalServerContext {
    let (client_ws_sender, server_ws_receiver) = mpsc::unbounded_channel();
    let (server_ws_sender, _) = broadcast::channel(16);

    // server_ws_sender -> client_ws_receiver
    // server_ws_receiver <- client_ws_sender
    let local_ws = LocalWebSocket::new(server_ws_receiver, server_ws_sender.clone());
    let client_ws_receiver = server_ws_sender;
    let local_server = LocalServer::new(client_ws_sender, client_ws_receiver);

    LocalServerContext { local_ws, local_server }
}
