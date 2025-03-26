use crate::mcp::util::map_mcp_error;
use flowy_error::{FlowyError, FlowyResult};
use mcp_daemon::transport::{ClientStdioTransport, Transport};
use mcp_daemon::types::Implementation;
use mcp_daemon::Client;

pub struct MCPServerConfig {
  server_cmd: String,
  args: Vec<String>,
}

impl MCPServerConfig {
  pub fn is_sse_server(&self) -> bool {
    self.server_cmd.starts_with("http")
  }
}

// https://modelcontextprotocol.io/docs/concepts/tools
#[derive(Clone)]
pub struct MCPClient {
  pub client: Client<ClientStdioTransport>,
  pub transport: ClientStdioTransport,
}

impl MCPClient {
  pub async fn initialize(&self) -> Result<(), FlowyError> {
    self.transport.open().await.map_err(map_mcp_error)?;
    self.client.start().await.map_err(map_mcp_error)?;

    let implementation = Implementation {
      name: "test".to_string(),
      version: "0.0.1".to_string(),
    };
    self
      .client
      .initialize(implementation)
      .map(|err| map_mcp_error)?;
    Ok(())
  }

  pub async fn stop(&mut self) -> FlowyResult<()> {
    self.transport.close().await.map_err(map_mcp_error)?;
    Ok(())
  }
}
