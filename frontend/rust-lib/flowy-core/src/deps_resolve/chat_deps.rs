use flowy_chat::manager::ChatManager;
use std::sync::Arc;

pub struct ChatDepsResolver;

impl ChatDepsResolver {
  pub fn resolve() -> Arc<ChatManager> {
    Arc::new(ChatManager::new())
  }
}
