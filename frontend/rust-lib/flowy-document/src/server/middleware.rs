use backend_service::{request::ResponseMiddleware, response::FlowyResponse};
use lazy_static::lazy_static;
use std::sync::Arc;

lazy_static! {
    pub(crate) static ref MIDDLEWARE: Arc<DocMiddleware> = Arc::new(DocMiddleware {});
}

pub(crate) struct DocMiddleware {}
impl ResponseMiddleware for DocMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                log::error!("document user is unauthorized");

                match token {
                    None => {},
                    Some(_token) => {
                        // let error =
                        // FlowyError::new(ErrorCode::UserUnauthorized, "");
                        // observable(token,
                        // WorkspaceObservable::UserUnauthorized).error(error).
                        // build()
                    },
                }
            }
        }
    }
}
