use crate::entities::NetworkStatePB;
use flowy_client_ws::{FlowyWebSocketConnect, NetworkType};
use flowy_error::FlowyError;
use lib_dispatch::prelude::{AFPluginData, AFPluginState};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, ws_manager))]
pub async fn update_network_ty(
  data: AFPluginData<NetworkStatePB>,
  ws_manager: AFPluginState<Arc<FlowyWebSocketConnect>>,
) -> Result<(), FlowyError> {
  let network_type: NetworkType = data.into_inner().ty.into();
  ws_manager.update_network_type(network_type);
  Ok(())
}
