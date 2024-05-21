use flowy_chat_pub::cloud::ChatCloudService;
use flowy_error::FlowyError;
use std::sync::Arc;

pub struct ChatManager {
  cloud_service: Arc<dyn ChatCloudService>,
}

impl ChatManager {
  pub fn new() -> ChatManager {
    todo!()
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }
}
