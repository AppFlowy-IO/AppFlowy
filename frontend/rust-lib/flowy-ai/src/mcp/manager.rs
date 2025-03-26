use crate::mcp::client::MCPClient;
use anyhow::Context;
use dashmap::DashMap;
use flowy_error::{ErrorCode, FlowyError};
use mcp_daemon::transport::{
  ClientHttpTransport, ClientStdioTransport, ServerStdioTransport, Transport, TransportError,
};
use mcp_daemon::types::Implementation;
use mcp_daemon::Client;
use serde_json::Value;
use std::io::{BufRead, BufReader};
use std::process::{Child, Command, Stdio};
use std::sync::Arc;
use std::thread;
use tracing::{debug, info};

pub struct MCPServerConfig {
  server_cmd: String,
  args: Vec<String>,
}

impl MCPServerConfig {
  pub fn is_sse_server(&self) -> bool {
    self.server_cmd.starts_with("http")
  }
}

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
    let client = connect_to_stdio_server(&config.server_cmd, config.args.as_ref()).await?;
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
}

async fn connect_to_stdio_server(command: &str, args: &[&str]) -> Result<MCPClient, FlowyError> {
  info!(
    "Connecting to running server with command: {} {}",
    command,
    args.join(" ")
  );

  let transport = ClientStdioTransport::new(command, args).map_err(map_mcp_error)?;
  let client = Client::builder(transport.clone()).build();
  Ok(MCPClient { client, transport })
}

fn map_mcp_error(err: TransportError) -> FlowyError {
  FlowyError::new(ErrorCode::MCPError, err.to_string())
}
