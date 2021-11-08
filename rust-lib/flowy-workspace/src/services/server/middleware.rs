use std::sync::Arc;

use lazy_static::lazy_static;

use flowy_net::{request::ResponseMiddleware, response::FlowyResponse};

use crate::{
    errors::{ErrorCode, WorkspaceError},
    notify::*,
};

lazy_static! {
    pub(crate) static ref MIDDLEWARE: Arc<WorkspaceMiddleware> = Arc::new(WorkspaceMiddleware {});
}

pub(crate) struct WorkspaceMiddleware {}
impl ResponseMiddleware for WorkspaceMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                log::error!("workspace user is unauthorized");

                match token {
                    None => {},
                    Some(token) => {
                        let error = WorkspaceError::new(ErrorCode::UserUnauthorized, "");
                        send_dart_notification(token, WorkspaceNotification::UserUnauthorized)
                            .error(error)
                            .send()
                    },
                }
            }
        }
    }
}
