use crate::error::SidecarError;
use crate::manager::WeakSidecarState;
use std::fmt::{Display, Formatter};

use crate::core::parser::ResponseParser;
use crate::core::rpc_loop::RpcLoop;
use crate::core::rpc_peer::{CloneableCallback, OneShotCallback};
use anyhow::anyhow;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value as JsonValue};
use std::io::BufReader;
use std::path::PathBuf;
use std::process::{Child, Stdio};
use std::sync::Arc;
use std::thread;
use std::time::Instant;
use tokio_stream::wrappers::ReceiverStream;

use tracing::{error, info};

#[derive(
  Default, Debug, Clone, Copy, Hash, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize,
)]
pub struct PluginId(pub(crate) i64);

impl From<i64> for PluginId {
  fn from(id: i64) -> Self {
    PluginId(id)
  }
}

/// The `Peer` trait defines the interface for the opposite side of the RPC channel,
/// designed to be used behind a pointer or as a trait object.
pub trait Peer: Send + Sync + 'static {
  /// Clones the peer into a boxed trait object.
  fn box_clone(&self) -> Arc<dyn Peer>;

  /// Sends an RPC notification to the peer with the specified method and parameters.
  fn send_rpc_notification(&self, method: &str, params: &JsonValue);

  fn stream_rpc_request(&self, method: &str, params: &JsonValue, f: CloneableCallback);

  fn async_send_rpc_request(&self, method: &str, params: &JsonValue, f: Box<dyn OneShotCallback>);
  /// Sends a synchronous RPC request to the peer and waits for the result.
  /// Returns the result of the request or an error.
  fn send_rpc_request(&self, method: &str, params: &JsonValue) -> Result<JsonValue, SidecarError>;

  /// Checks if there is an incoming request pending, intended to reduce latency for bulk operations done in the background.
  fn request_is_pending(&self) -> bool;

  /// Schedules a timer to execute the handler's `idle` function after the specified `Instant`.
  /// Note: This is not a high-fidelity timer. Regular RPC messages will always take priority over idle tasks.
  fn schedule_timer(&self, after: Instant, token: usize);
}

/// The `Peer` trait object.
pub type RpcPeer = Arc<dyn Peer>;

pub struct RpcCtx {
  pub peer: RpcPeer,
}

#[derive(Clone)]
pub struct Plugin {
  peer: RpcPeer,
  pub(crate) id: PluginId,
  pub(crate) name: String,
  #[allow(dead_code)]
  pub(crate) process: Arc<Child>,
}

impl Display for Plugin {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "{}, plugin id: {:?}, process id: {}",
      self.name,
      self.id,
      self.process.id()
    )
  }
}

impl Plugin {
  pub fn initialize(&self, value: JsonValue) -> Result<(), SidecarError> {
    self.peer.send_rpc_request("initialize", &value)?;
    Ok(())
  }

  pub fn request(&self, method: &str, params: &JsonValue) -> Result<JsonValue, SidecarError> {
    self.peer.send_rpc_request(method, params)
  }

  pub async fn async_request<P: ResponseParser>(
    &self,
    method: &str,
    params: &JsonValue,
  ) -> Result<P::ValueType, SidecarError> {
    let (tx, rx) = tokio::sync::oneshot::channel();
    self.peer.async_send_rpc_request(
      method,
      params,
      Box::new(move |result| {
        let _ = tx.send(result);
      }),
    );
    let value = rx.await.map_err(|err| {
      SidecarError::Internal(anyhow!("error waiting for async response: {:?}", err))
    })??;
    let value = P::parse_json(value)?;
    Ok(value)
  }

  pub fn stream_request<P: ResponseParser>(
    &self,
    method: &str,
    params: &JsonValue,
  ) -> Result<ReceiverStream<Result<P::ValueType, SidecarError>>, SidecarError> {
    let (tx, stream) = tokio::sync::mpsc::channel(100);
    let stream = ReceiverStream::new(stream);
    let callback = CloneableCallback::new(move |result| match result {
      Ok(json) => {
        let result = P::parse_json(json).map_err(SidecarError::from);
        let _ = tx.blocking_send(result);
      },
      Err(err) => {
        let _ = tx.blocking_send(Err(err));
      },
    });
    self.peer.stream_rpc_request(method, params, callback);
    Ok(stream)
  }

  pub fn shutdown(&self) {
    match self.peer.send_rpc_request("shutdown", &json!({})) {
      Ok(_) => {
        info!("shutting down plugin {}", self);
      },
      Err(err) => {
        error!("error sending shutdown to plugin {}: {:?}", self, err);
      },
    }
  }
}

pub struct PluginInfo {
  pub name: String,
  pub exec_path: PathBuf,
}

pub(crate) async fn start_plugin_process(
  plugin_info: PluginInfo,
  id: PluginId,
  state: WeakSidecarState,
) -> Result<(), anyhow::Error> {
  let (tx, rx) = tokio::sync::oneshot::channel();
  let spawn_result = thread::Builder::new()
    .name(format!("<{}> core host thread", &plugin_info.name))
    .spawn(move || {
      info!("Load {} plugin", &plugin_info.name);
      let child = std::process::Command::new(&plugin_info.exec_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn();

      match child {
        Ok(mut child) => {
          let child_stdin = child.stdin.take().unwrap();
          let child_stdout = child.stdout.take().unwrap();
          let mut looper = RpcLoop::new(child_stdin);
          let peer: RpcPeer = Arc::new(looper.get_raw_peer());
          let name = plugin_info.name.clone();
          peer.send_rpc_notification("ping", &JsonValue::Array(Vec::new()));

          let plugin = Plugin {
            peer,
            process: Arc::new(child),
            name,
            id,
          };

          state.plugin_connect(Ok(plugin));
          let _ = tx.send(());
          let mut state = state;
          let err = looper.mainloop(
            &plugin_info.name,
            || BufReader::new(child_stdout),
            &mut state,
          );
          state.plugin_exit(id, err);
        },
        Err(err) => {
          let _ = tx.send(());
          state.plugin_connect(Err(err))
        },
      }
    });

  if let Err(err) = spawn_result {
    error!("[RPC] thread spawn failed for {:?}, {:?}", id, err);
    return Err(err.into());
  }
  rx.await?;
  Ok(())
}
