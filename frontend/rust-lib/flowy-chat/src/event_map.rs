use std::sync::Weak;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::event_handler::*;
use crate::manager::ChatManager;

pub fn init(chat_manager: Weak<ChatManager>) -> AFPlugin {
  AFPlugin::new()
    .name("Flowy-Chat")
    .state(chat_manager)
    .event(ChatEvent::StreamMessage, stream_chat_message_handler)
    .event(ChatEvent::LoadPrevMessage, load_prev_message_handler)
    .event(ChatEvent::LoadNextMessage, load_next_message_handler)
    .event(ChatEvent::GetRelatedQuestion, get_related_question_handler)
    .event(ChatEvent::GetAnswerForQuestion, get_answer_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum ChatEvent {
  /// Create a new workspace
  #[event(input = "LoadPrevChatMessagePB", output = "ChatMessageListPB")]
  LoadPrevMessage = 0,

  #[event(input = "LoadNextChatMessagePB", output = "ChatMessageListPB")]
  LoadNextMessage = 1,

  #[event(input = "StreamChatPayloadPB", output = "ChatMessagePB")]
  StreamMessage = 2,

  // #[event(input = "StreamChatPayloadPB", output = "ChatMessagePB")]
  // StopStream= 3,
  #[event(input = "ChatMessageIdPB", output = "RepeatedRelatedQuestionPB")]
  GetRelatedQuestion = 4,

  #[event(input = "ChatMessageIdPB", output = "ChatMessagePB")]
  GetAnswerForQuestion = 5,
}
