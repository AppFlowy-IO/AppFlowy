use flowy_net::{request::ResponseMiddleware, response::FlowyResponse};
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::broadcast;
lazy_static! {
    pub static ref BACKEND_API_MIDDLEWARE: Arc<WorkspaceMiddleware> = Arc::new(WorkspaceMiddleware::new());
}

pub struct WorkspaceMiddleware {
    invalid_token_sender: broadcast::Sender<String>,
}

impl WorkspaceMiddleware {
    fn new() -> Self {
        let (sender, _) = broadcast::channel(10);
        WorkspaceMiddleware {
            invalid_token_sender: sender,
        }
    }

    pub fn invalid_token_subscribe(&self) -> broadcast::Receiver<String> { self.invalid_token_sender.subscribe() }
}

impl ResponseMiddleware for WorkspaceMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                log::error!("user is unauthorized");
                match token {
                    None => {},
                    Some(token) => match self.invalid_token_sender.send(token.clone()) {
                        Ok(_) => {},
                        Err(e) => log::error!("{:?}", e),
                    },
                }
            }
        }
    }
}
