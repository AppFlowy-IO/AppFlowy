use crate::core::parser::ResponseParser;
use crate::core::plugin::{start_plugin_process, Plugin, PluginId, PluginInfo, RpcCtx};
use crate::core::rpc_loop::Handler;
use crate::core::rpc_peer::{PluginCommand, ResponsePayload};
use crate::error::{ReadError, RemoteError, SidecarError};
use anyhow::anyhow;
use lib_infra::util::{get_operating_system, OperatingSystem};
use parking_lot::Mutex;
use serde_json::Value;
use std::io;

use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Weak};
use tracing::{error, info, instrument, trace, warn};

pub struct SidecarManager {
  state: Arc<Mutex<SidecarState>>,
  plugin_id_counter: Arc<AtomicI64>,
  operating_system: OperatingSystem,
}

impl Default for SidecarManager {
  fn default() -> Self {
    Self::new()
  }
}

impl SidecarManager {
  pub fn new() -> Self {
    SidecarManager {
      state: Arc::new(Mutex::new(SidecarState {
        plugins: Vec::new(),
      })),
      plugin_id_counter: Arc::new(Default::default()),
      operating_system: get_operating_system(),
    }
  }

  pub async fn create_plugin(&self, plugin_info: PluginInfo) -> Result<PluginId, SidecarError> {
    if self.operating_system.is_not_desktop() {
      return Err(SidecarError::Internal(anyhow!(
        "plugin not supported on this platform"
      )));
    }
    let plugin_id = PluginId::from(self.plugin_id_counter.fetch_add(1, Ordering::SeqCst));
    let weak_state = WeakSidecarState(Arc::downgrade(&self.state));
    start_plugin_process(plugin_info, plugin_id, weak_state).await?;
    Ok(plugin_id)
  }

  pub async fn get_plugin(&self, plugin_id: PluginId) -> Result<Weak<Plugin>, SidecarError> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == plugin_id)
      .ok_or(anyhow!("plugin not found"))?;
    Ok(Arc::downgrade(plugin))
  }

  #[instrument(skip(self), err)]
  pub async fn remove_plugin(&self, id: PluginId) -> Result<(), SidecarError> {
    if self.operating_system.is_not_desktop() {
      return Err(SidecarError::Internal(anyhow!(
        "plugin not supported on this platform"
      )));
    }

    info!("[RPC] removing plugin {:?}", id);
    self.state.lock().plugin_disconnect(id, Ok(()));
    Ok(())
  }

  pub fn init_plugin(&self, id: PluginId, init_params: Value) -> Result<Arc<Plugin>, SidecarError> {
    if self.operating_system.is_not_desktop() {
      return Err(SidecarError::Internal(anyhow!(
        "plugin not supported on this platform"
      )));
    }

    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    plugin.initialize(init_params)?;

    Ok(plugin.clone())
  }

  pub fn send_request<P: ResponseParser>(
    &self,
    id: PluginId,
    method: &str,
    request: Value,
  ) -> Result<P::ValueType, SidecarError> {
    let state = self.state.lock();
    let plugin = state
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))?;
    let resp = plugin.request(method, &request)?;
    let value = P::parse_json(resp)?;
    Ok(value)
  }

  pub async fn async_send_request<P: ResponseParser>(
    &self,
    id: PluginId,
    method: &str,
    request: Value,
  ) -> Result<P::ValueType, SidecarError> {
    let plugin = self
      .state
      .lock()
      .plugins
      .iter()
      .find(|p| p.id == id)
      .ok_or(anyhow!("plugin not found"))
      .cloned()?;
    let value = plugin.async_request::<P>(method, &request).await?;
    Ok(value)
  }
}

pub struct SidecarState {
  plugins: Vec<Arc<Plugin>>,
}

impl SidecarState {
  pub fn plugin_connect(&mut self, plugin: Result<Plugin, io::Error>) {
    match plugin {
      Ok(plugin) => {
        info!("[RPC] {} connected", plugin);
        self.plugins.push(Arc::new(plugin));
      },
      Err(err) => {
        warn!("plugin failed to connect: {:?}", err);
      },
    }
  }

  pub fn plugin_disconnect(
    &mut self,
    id: PluginId,
    error: Result<(), ReadError>,
  ) -> Option<Arc<Plugin>> {
    if let Err(err) = error {
      error!("[RPC] plugin {:?} exited with result {:?}", id, err)
    }

    let running_idx = self.plugins.iter().position(|p| p.id == id);
    match running_idx {
      Some(idx) => {
        let plugin = self.plugins.remove(idx);
        plugin.shutdown();
        Some(plugin)
      },
      None => {
        warn!("[RPC] plugin {:?} not found", id);
        None
      },
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
      core.lock().plugin_disconnect(plugin, error);
    }
  }
}

impl Handler for WeakSidecarState {
  type Request = PluginCommand<String>;

  fn handle_request(
    &mut self,
    _ctx: &RpcCtx,
    rpc: Self::Request,
  ) -> Result<ResponsePayload, RemoteError> {
    trace!("handling request: {:?}", rpc.cmd);
    Ok(ResponsePayload::empty_json())
  }
}
