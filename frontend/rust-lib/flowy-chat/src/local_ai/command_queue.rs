use std::cmp::Ordering;
use std::collections::BinaryHeap;
use tokio::sync::RwLock;

pub struct CommandQueue {
  queue: RwLock<BinaryHeap<LocalLLMCommand>>,
}

impl CommandQueue {
  pub fn new() -> Self {
    Self {
      queue: Default::default(),
    }
  }

  pub async fn push(&self, command: LocalLLMCommand) {
    self.queue.write().await.push(command);
  }

  pub async fn pop(&self) -> Option<LocalLLMCommand> {
    self.queue.write().await.pop()
  }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum LocalLLMCommand {
  OpenChat { chat_id: String },
  AskQuestion { chat_id: String, message: String },
  CloseChat { chat_id: String },
}

impl PartialOrd for LocalLLMCommand {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
    Some(self.cmp(other))
  }
}

impl Ord for LocalLLMCommand {
  fn cmp(&self, other: &Self) -> Ordering {
    match (self, other) {
      // Open chat
      (
        LocalLLMCommand::OpenChat { chat_id: chat_id1 },
        LocalLLMCommand::OpenChat { chat_id: chat_id2 },
      ) => chat_id1.cmp(chat_id2),
      (LocalLLMCommand::OpenChat { .. }, _) => Ordering::Greater,
      (_, LocalLLMCommand::OpenChat { .. }) => Ordering::Less,
      // Close chat
      (
        LocalLLMCommand::CloseChat { chat_id: chat_id1 },
        LocalLLMCommand::CloseChat { chat_id: chat_id2 },
      ) => chat_id1.cmp(chat_id2),
      (LocalLLMCommand::CloseChat { .. }, _) => Ordering::Greater,
      (_, LocalLLMCommand::CloseChat { .. }) => Ordering::Less,
      // Others
      _ => Ordering::Equal,
    }
  }
}
