use std::sync::{Arc, Weak};

use strum_macros::Display;

use crate::tools::AITools;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::chat_manager::ChatManager;
use crate::event_handler::*;

pub fn init(chat_manager: Weak<ChatManager>) -> AFPlugin {
  let user_service = Arc::downgrade(&chat_manager.upgrade().unwrap().user_service);
  let cloud_service = Arc::downgrade(&chat_manager.upgrade().unwrap().chat_service_wm);
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
    .event(
      ChatEvent::RefreshLocalAIModelInfo,
      refresh_local_ai_info_handler,
    )
    .event(ChatEvent::UpdateLocalLLM, update_local_llm_model_handler)
    .event(ChatEvent::GetLocalLLMState, get_local_llm_state_handler)
    .event(ChatEvent::CompleteText, start_complete_text_handler)
    .event(ChatEvent::StopCompleteText, stop_complete_text_handler)
    .event(ChatEvent::ChatWithFile, chat_file_handler)
    .event(
      ChatEvent::DownloadLLMResource,
      download_llm_resource_handler,
    )
    .event(
      ChatEvent::CancelDownloadLLMResource,
      cancel_download_llm_resource_handler,
    )
    .event(ChatEvent::GetLocalAIPluginState, get_plugin_state_handler)
    .event(ChatEvent::ToggleLocalAIChat, toggle_local_ai_chat_handler)
    .event(
      ChatEvent::GetLocalAIChatState,
      get_local_ai_chat_state_handler,
    )
    .event(ChatEvent::RestartLocalAIChat, restart_local_ai_chat_handler)
    .event(ChatEvent::ToggleLocalAI, toggle_local_ai_handler)
    .event(ChatEvent::GetLocalAIState, get_local_ai_state_handler)
    .event(
      ChatEvent::ToggleChatWithFile,
      toggle_local_ai_chat_file_handler,
    )
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

  #[event(input = "LLMModelPB", output = "LocalModelResourcePB")]
  UpdateLocalLLM = 6,

  #[event(output = "LocalModelResourcePB")]
  GetLocalLLMState = 7,

  #[event(output = "LLMModelInfoPB")]
  RefreshLocalAIModelInfo = 8,

  #[event(input = "CompleteTextPB", output = "CompleteTextTaskPB")]
  CompleteText = 9,

  #[event(input = "CompleteTextTaskPB")]
  StopCompleteText = 10,

  #[event(input = "ChatFilePB")]
  ChatWithFile = 11,

  #[event(input = "DownloadLLMPB", output = "DownloadTaskPB")]
  DownloadLLMResource = 12,

  #[event()]
  CancelDownloadLLMResource = 13,

  #[event(output = "LocalAIPluginStatePB")]
  GetLocalAIPluginState = 14,

  #[event(output = "LocalAIChatPB")]
  ToggleLocalAIChat = 15,

  /// Return Local AI Chat State
  #[event(output = "LocalAIChatPB")]
  GetLocalAIChatState = 16,

  /// Restart local AI chat. When plugin quit or user terminate in task manager or activity monitor,
  /// the plugin will need to restart.
  #[event()]
  RestartLocalAIChat = 17,

  /// Enable or disable local AI
  #[event(output = "LocalAIPB")]
  ToggleLocalAI = 18,

  /// Return LocalAIPB that contains the current state of the local AI
  #[event(output = "LocalAIPB")]
  GetLocalAIState = 19,

  #[event()]
  ToggleChatWithFile = 20,
}
