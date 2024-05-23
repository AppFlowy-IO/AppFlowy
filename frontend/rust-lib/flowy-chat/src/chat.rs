use flowy_chat_pub::cloud::ChatCloudService;
use std::sync::Arc;

pub struct Chat {
  chat_id: String,
  cloud_service: Arc<dyn ChatCloudService>,
}

impl Chat {
  pub fn new(chat_id: String, cloud_service: Arc<dyn ChatCloudService>) -> Chat {
    Chat {
      chat_id,
      cloud_service,
    }
  }
}
