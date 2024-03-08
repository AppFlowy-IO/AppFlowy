use crate::{ObjectIdentity, ObjectValue};
use flowy_error::FlowyError;

pub async fn object_from_disk(
  _workspace_id: &str,
  _local_file_path: &str,
) -> Result<(ObjectIdentity, ObjectValue), FlowyError> {
  Err(
    FlowyError::not_support()
      .with_context(format!("object_from_disk is not implemented for wasm32")),
  )
}
