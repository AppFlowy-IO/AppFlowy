use crate::error::Error;
use crate::manager::WeakSidecarState;

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::BufReader;

use std::process::{Child, Stdio};
use std::sync::Arc;

use crate::core::parser::ResponseParser;
use crate::core::rpc_loop::RpcLoop;
use anyhow::anyhow;
use std::thread;
use std::time::Instant;
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

pub trait Callback: Send {
  fn call(self: Box<Self>, result: Result<Value, Error>);
}

impl<F: Send + FnOnce(Result<Value, Error>)> Callback for F {
  fn call(self: Box<F>, result: Result<Value, Error>) {
    (*self)(result)
  }
}

/// The `Peer` trait defines the interface for the opposite side of the RPC channel,
/// designed to be used behind a pointer or as a trait object.
pub trait Peer: Send + Sync + 'static {
  /// Clones the peer into a boxed trait object.
  fn box_clone(&self) -> Arc<dyn Peer>;

  /// Sends an RPC notification to the peer with the specified method and parameters.
  fn send_rpc_notification(&self, method: &str, params: &Value);

  /// Sends an asynchronous RPC request to the peer and executes the provided callback upon completion.
  fn send_rpc_request_async(&self, method: &str, params: &Value, f: Box<dyn Callback>);

  /// Sends a synchronous RPC request to the peer and waits for the result.
  /// Returns the result of the request or an error.
  fn send_rpc_request(&self, method: &str, params: &Value) -> Result<Value, Error>;

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
  process: Arc<Child>,
}

impl Plugin {
  pub fn initialize(&self, value: Value) -> Result<(), Error> {
    self.peer.send_rpc_request("initialize", &value)?;
    Ok(())
  }

  pub fn send_request(&self, method: &str, params: &Value) -> Result<Value, Error> {
    self.peer.send_rpc_request(method, params)
  }

  pub async fn async_send_request<P: ResponseParser>(
    &self,
    method: &str,
    params: &Value,
  ) -> Result<P::ValueType, Error> {
    let (tx, rx) = tokio::sync::oneshot::channel();
    self.peer.send_rpc_request_async(
      method,
      params,
      Box::new(move |result| {
        let _ = tx.send(result);
      }),
    );
    let value = rx
      .await
      .map_err(|err| Error::Internal(anyhow!("error waiting for async response: {:?}", err)))??;
    let value = P::parse_response(value)?;
    Ok(value)
  }

  pub fn shutdown(&self) {
    if let Err(err) = self.peer.send_rpc_request("shutdown", &json!({})) {
      error!("error sending shutdown to plugin {}: {:?}", self.name, err);
    }
  }
}

pub struct PluginInfo {
  pub name: String,
  pub exec_path: String,
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
          peer.send_rpc_notification("ping", &Value::Array(Vec::new()));

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
