use crate::error::{ReadError, RemoteError};
use crate::parser::ResponseParser;
use crate::plugin::{start_plugin_process, Plugin, PluginId, PluginInfo, RpcCtx};
use crate::rpc_loop::Handler;
use crate::rpc_peer::PluginCommand;
use anyhow::{anyhow, Result};
use parking_lot::Mutex;
use serde_json::{json, Value};
use std::io;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Weak};
use tracing::{trace, warn};

pub struct SidecarManager {
  state: Arc<Mutex<SidecarState>>,
  plugin_id_counter: Arc<AtomicI64>,
}

impl SidecarManager {
  pub fn new() -> Self {
    SidecarManager {
      state: Arc::new(Mutex::new(SidecarState {
        plugins: Vec::new(),
      })),
      plugin_id_counter: Arc::new(Default::default()),
    }
  }

  pub async fn create_plugin(&self, plugin_info: PluginInfo) -> Result<PluginId> {
    let plugin_id = PluginId::from(self.plugin_id_counter.fetch_add(1, Ordering::SeqCst));
    let weak_state = WeakSidecarState(Arc::downgrade(&self.state));
    start_plugin_process(plugin_info, plugin_id, weak_state).await?;
    Ok(plugin_id)
  }

  pub async fn remove_plugin(&self, id: PluginId) -> Result<()> {
    let mut state = self.state.lock();
    state.plugin_disconnect(id, Ok(()));
    Ok(())
  }

  pub fn init_plugin(&self, id: PluginId, init_params: Value) -> Result<()> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    plugin.initialize(init_params)?;

    Ok(())
  }

  pub fn send_request<P: ResponseParser>(
    &self,
    id: PluginId,
    method: &str,
    request: Value,
  ) -> Result<P::ValueType> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    let resp = plugin.send_request(method, &request)?;
    let value = P::parse_response(resp)?;
    Ok(value)
  }
}

pub struct SidecarState {
  plugins: Vec<Plugin>,
}

impl SidecarState {
  pub fn plugin_connect(&mut self, plugin: Result<Plugin, io::Error>) {
    match plugin {
      Ok(plugin) => {
        trace!("plugin connected: {:?}", plugin.id);
        self.plugins.push(plugin);
      },
      Err(err) => {
        warn!("plugin failed to connect: {:?}", err);
      },
    }
  }

  pub fn plugin_disconnect(&mut self, id: PluginId, error: Result<(), ReadError>) {
    if let Err(err) = error {
      warn!("[RPC] plugin {:?} exited with result {:?}", id, err);
    }
    let running_idx = self.plugins.iter().position(|p| p.id == id);
    if let Some(idx) = running_idx {
      let plugin = self.plugins.remove(idx);
      plugin.shutdown();
    }
  }
}

#[derive(Clone)]
pub struct WeakSidecarState(Weak<Mutex<SidecarState>>);

impl WeakSidecarState {
  pub fn upgrade(&self) -> Option<Arc<Mutex<SidecarState>>> {
    self.0.upgrade()
  }

  pub fn plugin_connect(&self, plugin: Result<Plugin, io::Error>) {
    if let Some(state) = self.upgrade() {
      state.lock().plugin_connect(plugin)
    }
  }

  pub fn plugin_exit(&self, plugin: PluginId, error: Result<(), ReadError>) {
    if let Some(core) = self.upgrade() {
      core.lock().plugin_disconnect(plugin, error)
    }
  }
}

impl Handler for WeakSidecarState {
  type Request = PluginCommand<String>;

  fn handle_request(&mut self, _ctx: &RpcCtx, rpc: Self::Request) -> Result<Value, RemoteError> {
    trace!("handling request: {:?}", rpc.cmd);
    Ok(json!({}))
  }
}
