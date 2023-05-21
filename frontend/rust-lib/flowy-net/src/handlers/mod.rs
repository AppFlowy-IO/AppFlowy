use flowy_error::FlowyError;
use lib_dispatch::prelude::AFPluginData;

use crate::entities::NetworkStatePB;

pub async fn update_network_ty(_data: AFPluginData<NetworkStatePB>) -> Result<(), FlowyError> {
  Ok(())
}
