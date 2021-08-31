mod server_api;
mod server_api_mock;
pub use server_api::*;
pub use server_api_mock::*;

use std::sync::Arc;
pub(crate) fn construct_user_server() -> Arc<dyn UserServerAPI + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(UserServer {})
    } else {
        Arc::new(UserServerMock {})
    }
}
