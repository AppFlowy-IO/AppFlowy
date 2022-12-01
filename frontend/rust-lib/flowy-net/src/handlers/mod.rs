use crate::{entities::NetworkState, ws::connection::FlowyWebSocketConnect};
use flowy_error::FlowyError;
use lib_dispatch::prelude::{AFPluginData, AFPluginState};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, ws_manager))]
pub async fn update_network_ty(
    data: AFPluginData<NetworkState>,
    ws_manager: AFPluginState<Arc<FlowyWebSocketConnect>>,
) -> Result<(), FlowyError> {
    let network_state = data.into_inner();
    ws_manager.update_network_type(&network_state.ty);
    Ok(())
}
