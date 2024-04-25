use crate::af_cloud::define::ServerUser;
use flowy_error::{FlowyError, FlowyResult};
use std::sync::Arc;
use tracing::warn;

/// Validates the workspace_id provided in the request.
/// It checks that the workspace_id from the request matches the current user's active workspace_id.
/// This ensures that the operation is being performed in the correct workspace context, enhancing security.
pub fn check_request_workspace_id_is_match(
  expected_workspace_id: &str,
  user: &Arc<dyn ServerUser>,
) -> FlowyResult<()> {
  let actual_workspace_id = user.workspace_id()?;
  if expected_workspace_id != actual_workspace_id {
    warn!(
      "Expect workspace_id: {}, actual workspace_id: {}",
      expected_workspace_id, actual_workspace_id
    );

    return Err(
      FlowyError::internal()
        .with_context("Current workspace was changed when processing the request"),
    );
  }
  Ok(())
}
