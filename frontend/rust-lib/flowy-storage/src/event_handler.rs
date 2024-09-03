use crate::entities::RegisterStreamPB;
use crate::manager::StorageManager;
use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{AFPluginData, AFPluginState};
use std::sync::{Arc, Weak};

fn upgrade_storage_manager(
  ai_manager: AFPluginState<Weak<StorageManager>>,
) -> FlowyResult<Arc<StorageManager>> {
  let manager = ai_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The storage manager is already dropped"))?;
  Ok(manager)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn register_stream_handler(
  data: AFPluginData<RegisterStreamPB>,
  storage_manager: AFPluginState<Weak<StorageManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_storage_manager(storage_manager)?;
  let data = data.into_inner();
  manager.register_file_progress_stream(data.port).await;
  Ok(())
}
