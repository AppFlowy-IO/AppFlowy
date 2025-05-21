use af_mcp::client::{MCPClient, MCPServerConfig};
use af_mcp::entities::ToolsList;
use dashmap::DashMap;
use flowy_error::FlowyError;
use std::sync::Arc;

pub struct MCPClientManager {
  stdio_clients: Arc<DashMap<String, MCPClient>>,
}

impl MCPClientManager {
  pub fn new() -> MCPClientManager {
    Self {
      stdio_clients: Arc::new(DashMap::new()),
    }
  }

  pub async fn connect_server(&self, config: MCPServerConfig) -> Result<(), FlowyError> {
    let client = MCPClient::new_stdio(config.clone()).await?;
    self.stdio_clients.insert(config.server_cmd, client.clone());
    client.initialize().await?;
    Ok(())
  }

  pub async fn remove_server(&self, config: MCPServerConfig) -> Result<(), FlowyError> {
    let client = self.stdio_clients.remove(&config.server_cmd);
    if let Some((_, mut client)) = client {
      client.stop().await?;
    }
    Ok(())
  }

  pub async fn tool_list(&self, server_cmd: &str) -> Option<ToolsList> {
    let client = self.stdio_clients.get(server_cmd)?;
    let tools = client.list_tools().await.ok();
    tracing::trace!("{}: tool list: {:?}", server_cmd, tools);
    tools
  }
}
