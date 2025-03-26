use flowy_error::{ErrorCode, FlowyError};
use mcp_daemon::transport::TransportError;

pub(crate) fn map_mcp_error(err: TransportError) -> FlowyError {
  FlowyError::new(ErrorCode::MCPError, err.to_string())
}
