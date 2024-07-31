use std::sync::{Arc, Weak};

use strum_macros::Display;

use crate::tools::AITools;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::ai_manager::AIManager;
use crate::event_handler::*;

pub fn init(chat_manager: Weak<AIManager>) -> AFPlugin {
  let user_service = Arc::downgrade(&chat_manager.upgrade().unwrap().user_service);
  let cloud_service = Arc::downgrade(&chat_manager.upgrade().unwrap().cloud_service_wm);
  let ai_tools = Arc::new(AITools::new(cloud_service, user_service));
  AFPlugin::new()
    .name("flowy-ai")
    .state(chat_manager)
    .state(ai_tools)
    .event(AIEvent::StreamMessage, stream_chat_message_handler)
    .event(AIEvent::LoadPrevMessage, load_prev_message_handler)
    .event(AIEvent::LoadNextMessage, load_next_message_handler)
    .event(AIEvent::GetRelatedQuestion, get_related_question_handler)
    .event(AIEvent::GetAnswerForQuestion, get_answer_handler)
    .event(AIEvent::StopStream, stop_stream_handler)
    .event(
      AIEvent::RefreshLocalAIModelInfo,
      refresh_local_ai_info_handler,
    )
    .event(AIEvent::UpdateLocalLLM, update_local_llm_model_handler)
    .event(AIEvent::GetLocalLLMState, get_local_llm_state_handler)
    .event(AIEvent::CompleteText, start_complete_text_handler)
    .event(AIEvent::StopCompleteText, stop_complete_text_handler)
    .event(AIEvent::ChatWithFile, chat_file_handler)
    .event(AIEvent::DownloadLLMResource, download_llm_resource_handler)
    .event(
      AIEvent::CancelDownloadLLMResource,
      cancel_download_llm_resource_handler,
    )
    .event(AIEvent::GetLocalAIPluginState, get_plugin_state_handler)
    .event(AIEvent::ToggleLocalAIChat, toggle_local_ai_chat_handler)
    .event(
      AIEvent::GetLocalAIChatState,
      get_local_ai_chat_state_handler,
    )
    .event(AIEvent::RestartLocalAIChat, restart_local_ai_chat_handler)
    .event(AIEvent::ToggleLocalAI, toggle_local_ai_handler)
    .event(AIEvent::GetLocalAIState, get_local_ai_state_handler)
    .event(
      AIEvent::ToggleChatWithFile,
      toggle_local_ai_chat_file_handler,
    )
    .event(
      AIEvent::GetModelStorageDirectory,
      get_model_storage_directory_handler,
    )
    .event(AIEvent::GetOfflineAIAppLink, get_offline_app_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum AIEvent {
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

  #[event(output = "LocalModelStoragePB")]
  GetModelStorageDirectory = 21,

  #[event(output = "OfflineAIPB")]
  GetOfflineAIAppLink = 22,
}
