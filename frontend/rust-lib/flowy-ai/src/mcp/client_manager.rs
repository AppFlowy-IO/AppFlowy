use dashmap::DashMap;
use mcpr::transport::Transport;
use mcpr::{client::Client, transport::sse::SSETransport, transport::stdio::StdioTransport};
use std::sync::Arc;

pub struct MCPClientManager {
  stdio_clients: Arc<DashMap<String, Client<StdioTransport>>>,
  http_client: Arc<DashMap<String, Client<SSETransport>>>,
}

impl MCPClientManager {}
