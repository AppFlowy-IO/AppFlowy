pub use conn::*;
pub use manager::*;
use std::sync::Arc;

mod conn;
mod manager;
mod ws_local;

#[cfg(not(feature = "flowy_unit_test"))]
pub(crate) fn local_web_socket() -> Arc<dyn FlowyWebSocket> { Arc::new(Arc::new(ws_local::LocalWebSocket::default())) }

#[cfg(feature = "flowy_unit_test")]
pub(crate) fn local_web_socket() -> Arc<dyn FlowyWebSocket> {
    Arc::new(Arc::new(crate::services::mock::MockWebSocket::default()))
}
