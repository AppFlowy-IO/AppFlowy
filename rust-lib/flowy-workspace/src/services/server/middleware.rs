use lazy_static::lazy_static;
use std::sync::Arc;
lazy_static! {
    pub(crate) static ref MIDDLEWARE: Arc<WorkspaceMiddleware> = Arc::new(WorkspaceMiddleware {});
}

use crate::{
    errors::{ErrorCode, WorkspaceError},
    notify::*,
};
use flowy_net::{request::ResponseMiddleware, response::FlowyResponse};

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
                        dart_notify(token, Notification::UserUnauthorized).error(error).send()
                    },
                }
            }
        }
    }
}
