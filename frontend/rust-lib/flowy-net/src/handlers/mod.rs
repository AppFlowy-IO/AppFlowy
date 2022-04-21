use crate::{entities::NetworkState, ws::connection::FlowyWebSocketConnect};
use flowy_error::FlowyError;
use lib_dispatch::prelude::{AppData, Data};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, ws_manager))]
pub async fn update_network_ty(
    data: Data<NetworkState>,
    ws_manager: AppData<Arc<FlowyWebSocketConnect>>,
) -> Result<(), FlowyError> {
    let network_state = data.into_inner();
    ws_manager.update_network_type(&network_state.ty);
    Ok(())
}
