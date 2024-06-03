use flowy_chat_pub::cloud::{
  ChatMessage, RelatedQuestion, RepeatedChatMessage, RepeatedRelatedQuestion,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_infra::validator_fn::required_not_empty_str;
use validator::Validate;

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct SendChatPayloadPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub message: String,

  #[pb(index = 3)]
  pub message_type: ChatMessageTypePB,
}

#[derive(Debug, Default, Clone, ProtoBuf_Enum, PartialEq, Eq, Copy)]
pub enum ChatMessageTypePB {
  #[default]
  System = 0,
  User = 1,
}

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct LoadPrevChatMessagePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  pub limit: i64,

  #[pb(index = 4, one_of)]
  pub before_message_id: Option<i64>,
}

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct LoadNextChatMessagePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub chat_id: String,

  #[pb(index = 2)]
  pub limit: i64,

  #[pb(index = 4, one_of)]
  pub after_message_id: Option<i64>,
}

#[derive(Default, ProtoBuf, Validate, Clone, Debug)]
pub struct ChatMessageListPB {
  #[pb(index = 1)]
  pub has_more: bool,

  #[pb(index = 2)]
  pub messages: Vec<ChatMessagePB>,

  /// If the total number of messages is 0, then the total number of messages is unknown.
  #[pb(index = 3)]
  pub total: i64,
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
      total: repeated_chat_message.total,
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

  #[pb(index = 4)]
  pub author_type: i64,

  #[pb(index = 5)]
  pub author_id: String,

  #[pb(index = 6)]
  pub has_following: bool,

  #[pb(index = 7, one_of)]
  pub reply_message_id: Option<i64>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChatMessageErrorPB {
  #[pb(index = 1)]
  pub chat_id: String,

  #[pb(index = 2)]
  pub content: String,

  #[pb(index = 3)]
  pub error_message: String,
}

impl From<ChatMessage> for ChatMessagePB {
  fn from(chat_message: ChatMessage) -> Self {
    ChatMessagePB {
      message_id: chat_message.message_id,
      content: chat_message.content,
      created_at: chat_message.created_at.timestamp(),
      author_type: chat_message.author.author_type as i64,
      author_id: chat_message.author.author_id.to_string(),
      has_following: false,
      reply_message_id: None,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedChatMessagePB {
  #[pb(index = 1)]
  items: Vec<ChatMessagePB>,
}

impl From<Vec<ChatMessage>> for RepeatedChatMessagePB {
  fn from(messages: Vec<ChatMessage>) -> Self {
    RepeatedChatMessagePB {
      items: messages.into_iter().map(ChatMessagePB::from).collect(),
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChatMessageIdPB {
  #[pb(index = 1)]
  pub chat_id: String,

  #[pb(index = 2)]
  pub message_id: i64,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RelatedQuestionPB {
  #[pb(index = 1)]
  pub content: String,
}

impl From<RelatedQuestion> for RelatedQuestionPB {
  fn from(value: RelatedQuestion) -> Self {
    RelatedQuestionPB {
      content: value.content,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedRelatedQuestionPB {
  #[pb(index = 1)]
  pub message_id: i64,

  #[pb(index = 2)]
  pub items: Vec<RelatedQuestionPB>,
}

impl From<RepeatedRelatedQuestion> for RepeatedRelatedQuestionPB {
  fn from(value: RepeatedRelatedQuestion) -> Self {
    RepeatedRelatedQuestionPB {
      message_id: value.message_id,
      items: value
        .items
        .into_iter()
        .map(RelatedQuestionPB::from)
        .collect(),
    }
  }
}
