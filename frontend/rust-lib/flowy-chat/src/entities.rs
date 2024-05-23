use flowy_chat_pub::cloud::{ChatMessage, RepeatedChatMessage};
use flowy_derive::ProtoBuf;
use lib_infra::validator_fn::{required_not_empty_str, required_valid_path};
use validator::Validate;

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct SendChatPayloadPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub message: String,
}

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct LoadChatMessagePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  pub limit: i64,

  #[pb(index = 3, one_of)]
  pub after_message_id: Option<i64>,

  #[pb(index = 4, one_of)]
  pub before_message_id: Option<i64>,
}

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct ChatMessageListPB {
  #[pb(index = 1)]
  pub has_more: bool,

  #[pb(index = 2)]
  pub messages: Vec<ChatMessagePB>,
}

impl From<RepeatedChatMessage> for ChatMessageListPB {
  fn from(repeated_chat_message: RepeatedChatMessage) -> Self {
    let messages = repeated_chat_message
      .messages
      .into_iter()
      .map(ChatMessagePB::from)
      .collect();
    ChatMessageListPB {
      has_more: repeated_chat_message.has_more,
      messages,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChatMessagePB {
  #[pb(index = 1)]
  pub message_id: i64,

  #[pb(index = 2)]
  pub content: String,

  #[pb(index = 3)]
  pub created_at: i64,
}

impl From<ChatMessage> for ChatMessagePB {
  fn from(chat_message: ChatMessage) -> Self {
    ChatMessagePB {
      message_id: chat_message.message_id,
      content: chat_message.content,
      created_at: chat_message.created_at.timestamp(),
    }
  }
}
