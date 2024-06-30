use crate::{ErrorCode, FlowyError};
use flowy_sidecar::error::SidecarError;

impl std::convert::From<SidecarError> for FlowyError {
  fn from(error: SidecarError) -> Self {
    FlowyError::new(ErrorCode::LocalAIError, error)
  }
}
