use anyhow::Context;
use dashmap::DashMap;
use flowy_error::{ErrorCode, FlowyError};
use mcpr::error::MCPError;
use mcpr::schema::JSONRPCRequest;
use mcpr::transport::Transport;
use mcpr::{client::Client, transport::sse::SSETransport, transport::stdio::StdioTransport};
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

pub struct MCPClient<T: Transport> {
  client: Client<T>,
  process: Option<Child>,
}

impl<T> MCPClient<T>
where
  T: Transport,
{
  pub fn initialize(&mut self) -> Result<(), FlowyError> {
    self
      .client
      .initialize()
      .map(|err| FlowyError::new(ErrorCode::MCPError).with_context(err))?;
    Ok(())
  }
}

impl<T: Transport> Drop for MCPClient<T> {
  fn drop(&mut self) {
    if let Some(process) = &mut self.process {
      let _ = process.kill();
    }
  }
}

pub struct MCPClientManager {
  stdio_clients: Arc<DashMap<String, MCPClient<StdioTransport>>>,
  sse_clients: Arc<DashMap<String, MCPClient<SSETransport>>>,
}

impl MCPClientManager {
  pub fn new() -> MCPClientManager {
    Self {
      stdio_clients: Arc::new(DashMap::new()),
      sse_clients: Arc::new(DashMap::new()),
    }
  }

  pub async fn connect_server(&self, config: MCPServerConfig) -> Result<(), FlowyError> {
    if config.is_sse_server() {
      let context = connect_to_http_server(&config.server_cmd, &config.args).await?;
      self.sse_clients.insert(config.server_cmd, context);
    } else {
      let context = connect_to_stdio_server(&config.server_cmd, &config.args).await?;
      self.stdio_clients.insert(config.server_cmd, context);
    }
    Ok(())
  }

  pub async fn remove_server(&self, config: MCPServerConfig) -> Result<(), FlowyError> {
    if config.is_sse_server() {
      self.sse_clients.remove(&config.server_cmd);
    } else {
      self.stdio_clients.remove(&config.server_cmd);
    }
    Ok(())
  }
}

async fn connect_to_http_server(
  command: &str,
  args: &[String],
) -> Result<MCPClient<SSETransport>, FlowyError> {
  info!(
    "Connecting to running server with command: {} {}",
    command,
    args.join(" ")
  );

  let transport = SSETransport::new_server(&command);
  let client = Client::new(transport);
  Ok(MCPClient {
    client,
    process: None,
  })
}

async fn connect_to_stdio_server(
  command: &str,
  args: &[String],
) -> Result<MCPClient<StdioTransport>, FlowyError> {
  info!(
    "Connecting to running server with command: {} {}",
    command,
    args.join(" ")
  );

  // Start a new process that will connect to the server
  let mut process = Command::new(command)
    .args(args)
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .stderr(Stdio::piped())
    .spawn()
    .context("Failed to spawn process")?;

  if let Some(stderr) = process.stderr.take() {
    let stderr_reader = BufReader::new(stderr);
    thread::spawn(move || {
      for line in stderr_reader.lines() {
        if let Ok(line) = line {
          debug!("Server stderr: {}", line);
        }
      }
    });
  }

  let transport = StdioTransport::with_reader_writer(
    Box::new(process.stdout.take().context("Failed to get stdout")?),
    Box::new(process.stdin.take().context("Failed to get stdin")?),
  );

  let client = Client::new(transport);
  Ok(MCPClient {
    client,
    process: Some(process),
  })
}
