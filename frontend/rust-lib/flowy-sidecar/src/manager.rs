use crate::error::{ReadError, RemoteError};
use crate::plugin::{start_plugin_process, Plugin, PluginId, PluginInfo, RpcCtx};
use crate::rpc_loop::Handler;
use crate::rpc_peer::PluginCommand;
use anyhow::{anyhow, Result};
use parking_lot::{Mutex, RwLock};
use serde_json::{json, Value};
use std::io;
use std::sync::atomic::{AtomicI64, AtomicU8, Ordering};
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

  pub async fn kill_plugin(&self, id: PluginId) -> Result<()> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    plugin.shutdown()
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

  pub fn send_request(&self, id: PluginId, method: &str, request: Value) -> Result<()> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    plugin.send_request(method, &request)?;
    Ok(())
  }
}

pub struct SidecarState {
  plugins: Vec<Plugin>,
}

impl SidecarState {
  pub fn plugin_connect(&mut self, plugin: Result<Plugin, io::Error>) {
    match plugin {
      Ok(plugin) => {
        warn!("plugin connected: {:?}", plugin.id);
        self.plugins.push(plugin);
      },
      Err(err) => {
        warn!("plugin failed to connect: {:?}", err);
      },
    }
  }

  pub fn plugin_exit(&mut self, id: PluginId, error: Result<(), ReadError>) {
    warn!("plugin {:?} exited with result {:?}", id, error);
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
      core.lock().plugin_exit(plugin, error)
    }
  }
}

impl Handler for WeakSidecarState {
  type Request = PluginCommand<String>;

  fn handle_request(&mut self, ctx: &RpcCtx, rpc: Self::Request) -> Result<Value, RemoteError> {
    trace!("handling request: {:?}", rpc.cmd);
    Ok(json!({}))
  }
}
