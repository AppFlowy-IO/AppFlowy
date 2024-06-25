use crate::error::Error;
use crate::manager::WeakSidecarState;
use crate::rpc_loop::RpcLoop;

use anyhow::anyhow;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::BufReader;
use std::path::PathBuf;
use std::process::{Child, Stdio};
use std::sync::Arc;
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

/// The `Peer` trait represents the interface for the other side of the RPC
/// channel. It is intended to be used behind a pointer, a trait object.
pub trait Peer: Send + 'static {
  fn box_clone(&self) -> Box<dyn Peer>;
  fn send_rpc_request_async(&self, method: &str, params: &Value, f: Box<dyn Callback>);
  /// Sends a request (synchronous RPC) to the peer, and waits for the result.
  fn send_rpc_request(&self, method: &str, params: &Value) -> Result<Value, Error>;
  /// Determines whether an incoming request (or notification) is
  /// pending. This is intended to reduce latency for bulk operations
  /// done in the background.
  fn request_is_pending(&self) -> bool;

  fn schedule_idle(&self, token: usize);
  /// Like `schedule_idle`, with the guarantee that the handler's `idle`
  /// fn will not be called _before_ the provided `Instant`.
  ///
  /// # Note
  ///
  /// This is not intended as a high-fidelity timer. Regular RPC messages
  /// will always take priority over an idle task.
  fn schedule_timer(&self, after: Instant, token: usize);
}

/// The `Peer` trait object.
pub type RpcPeer = Box<dyn Peer>;

pub struct RpcCtx {
  pub peer: RpcPeer,
}
pub struct Plugin {
  peer: RpcPeer,
  pub(crate) id: PluginId,
  pub(crate) name: String,
  #[allow(dead_code)]
  process: Child,
}

impl Plugin {
  pub fn initialize(&self, value: Value) -> Result<(), Error> {
    self.peer.send_rpc_request("initialize", &value)?;
    Ok(())
  }

  pub fn send_request(&self, method: &str, params: &Value) -> Result<Value, Error> {
    self.peer.send_rpc_request(method, params)
  }

  pub fn shutdown(&self) {
    if let Err(err) = self.peer.send_rpc_request("shutdown", &json!({})) {
      error!("error sending shutdown to plugin {}: {:?}", self.name, err);
    }
  }
}

pub struct PluginInfo {
  pub name: String,
  // pub absolute_chat_model_path: String,
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
          let peer: RpcPeer = Box::new(looper.get_raw_peer());
          let name = plugin_info.name.clone();
          if let Err(err) = peer.send_rpc_request("ping", &Value::Array(Vec::new())) {
            error!("plugin {} failed to respond to ping: {:?}", name, err);
          }
          let plugin = Plugin {
            peer,
            process: child,
            name,
            id,
          };

          state.plugin_connect(Ok(plugin));
          let _ = tx.send(());
          let mut state = state;
          let err = looper.mainloop(|| BufReader::new(child_stdout), &mut state);
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
