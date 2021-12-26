use crate::{entities::NetworkState, services::ws::FlowyWSConnect};

use flowy_error::FlowyError;
use lib_dispatch::prelude::{Data, Unit};
use std::sync::Arc;

#[tracing::instrument(skip(data, ws_manager))]
pub async fn update_network_ty(
    data: Data<NetworkState>,
    ws_manager: Unit<Arc<FlowyWSConnect>>,
) -> Result<(), FlowyError> {
    let network_state = data.into_inner();
    ws_manager.update_network_type(&network_state.ty);
    Ok(())
}
