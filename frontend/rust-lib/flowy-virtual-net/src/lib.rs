use flowy_net::services::ws::FlowyWebSocket;
use std::sync::Arc;
mod ws;

#[cfg(not(feature = "flowy_unit_test"))]
pub fn local_web_socket() -> Arc<dyn FlowyWebSocket> { Arc::new(ws::LocalWebSocket::default()) }

#[cfg(feature = "flowy_unit_test")]
mod mock;

#[cfg(feature = "flowy_unit_test")]
pub fn local_web_socket() -> Arc<dyn FlowyWebSocket> { Arc::new(crate::mock::MockWebSocket::default()) }
