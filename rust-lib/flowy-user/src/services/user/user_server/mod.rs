mod server_api;
mod server_api_mock;

pub use server_api::*;
pub use server_api_mock::*;

use crate::services::workspace::UserWorkspaceController;
use std::sync::Arc;

pub(crate) fn construct_user_server(
    workspace_controller: Arc<dyn UserWorkspaceController + Send + Sync>,
) -> Arc<dyn UserServerAPI + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(UserServer {})
    } else {
        Arc::new(UserServerMock {
            workspace_controller,
        })
    }
}
