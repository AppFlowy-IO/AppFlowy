use std::sync::{Arc, Weak};

use strum_macros::Display;

use crate::tools::AITools;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::chat_manager::ChatManager;
use crate::event_handler::*;

pub fn init(chat_manager: Weak<ChatManager>) -> AFPlugin {
  let user_service = Arc::downgrade(&chat_manager.upgrade().unwrap().user_service);
  let cloud_service = Arc::downgrade(&chat_manager.upgrade().unwrap().chat_service);
  let ai_tools = Arc::new(AITools::new(cloud_service, user_service));
  AFPlugin::new()
    .name("Flowy-Chat")
    .state(chat_manager)
    .state(ai_tools)
    .event(ChatEvent::StreamMessage, stream_chat_message_handler)
    .event(ChatEvent::LoadPrevMessage, load_prev_message_handler)
    .event(ChatEvent::LoadNextMessage, load_next_message_handler)
    .event(ChatEvent::GetRelatedQuestion, get_related_question_handler)
    .event(ChatEvent::GetAnswerForQuestion, get_answer_handler)
    .event(ChatEvent::StopStream, stop_stream_handler)
    .event(ChatEvent::GetLocalAISetting, get_local_ai_setting_handler)
    .event(
      ChatEvent::UpdateLocalAISetting,
      update_local_ai_setting_handler,
    )
    .event(ChatEvent::CompleteText, start_complete_text_handler)
    .event(ChatEvent::StopCompleteText, stop_complete_text_handler)
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

  #[event(input = "StopStreamPB")]
  StopStream = 3,

  #[event(input = "ChatMessageIdPB", output = "RepeatedRelatedQuestionPB")]
  GetRelatedQuestion = 4,

  #[event(input = "ChatMessageIdPB", output = "ChatMessagePB")]
  GetAnswerForQuestion = 5,

  #[event(input = "LocalLLMSettingPB")]
  UpdateLocalAISetting = 6,

  #[event(output = "LocalLLMSettingPB")]
  GetLocalAISetting = 7,

  #[event(input = "CompleteTextPB", output = "CompleteTextTaskPB")]
  CompleteText = 8,

  #[event(input = "CompleteTextTaskPB")]
  StopCompleteText = 9,
}
