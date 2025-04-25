use std::sync::{Arc, Weak};

use strum_macros::Display;

use crate::completion::AICompletion;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::ai_manager::AIManager;
use crate::event_handler::*;

pub fn init(ai_manager: Weak<AIManager>) -> AFPlugin {
  let strong_ai_manager = ai_manager.upgrade().unwrap();
  let user_service = Arc::downgrade(&strong_ai_manager.user_service);
  let cloud_service = Arc::downgrade(&strong_ai_manager.cloud_service_wm);
  let ai_tools = Arc::new(AICompletion::new(cloud_service, user_service));
  AFPlugin::new()
    .name("flowy-ai")
    .state(ai_manager)
    .state(ai_tools)
    .event(AIEvent::StreamMessage, stream_chat_message_handler)
    .event(AIEvent::LoadPrevMessage, load_prev_message_handler)
    .event(AIEvent::LoadNextMessage, load_next_message_handler)
    .event(AIEvent::GetRelatedQuestion, get_related_question_handler)
    .event(AIEvent::GetAnswerForQuestion, get_answer_handler)
    .event(AIEvent::StopStream, stop_stream_handler)
    .event(AIEvent::CompleteText, start_complete_text_handler)
    .event(AIEvent::StopCompleteText, stop_complete_text_handler)
    .event(AIEvent::ChatWithFile, chat_file_handler)
    .event(AIEvent::RestartLocalAI, restart_local_ai_handler)
    .event(AIEvent::ToggleLocalAI, toggle_local_ai_handler)
    .event(AIEvent::GetLocalAIState, get_local_ai_state_handler)
    .event(AIEvent::GetLocalAISetting, get_local_ai_setting_handler)
    .event(AIEvent::GetLocalAIModels, get_local_ai_models_handler)
    .event(
      AIEvent::UpdateLocalAISetting,
      update_local_ai_setting_handler,
    )
    .event(
      AIEvent::GetServerAvailableModels,
      get_server_model_list_handler,
    )
    .event(AIEvent::CreateChatContext, create_chat_context_handler)
    .event(AIEvent::GetChatInfo, create_chat_context_handler)
    .event(AIEvent::GetChatSettings, get_chat_settings_handler)
    .event(AIEvent::UpdateChatSettings, update_chat_settings_handler)
    .event(AIEvent::RegenerateResponse, regenerate_response_handler)
    .event(AIEvent::GetAvailableModels, get_chat_models_handler)
    .event(AIEvent::UpdateSelectedModel, update_selected_model_handler)
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

  #[event(input = "CompleteTextPB", output = "CompleteTextTaskPB")]
  CompleteText = 9,

  #[event(input = "CompleteTextTaskPB")]
  StopCompleteText = 10,

  #[event(input = "ChatFilePB")]
  ChatWithFile = 11,

  /// Restart local AI chat. When plugin quit or user terminate in task manager or activity monitor,
  /// the plugin will need to restart.
  #[event()]
  RestartLocalAI = 17,

  /// Enable or disable local AI
  #[event(output = "LocalAIPB")]
  ToggleLocalAI = 18,

  /// Return LocalAIPB that contains the current state of the local AI
  #[event(output = "LocalAIPB")]
  GetLocalAIState = 19,

  #[event(input = "CreateChatContextPB")]
  CreateChatContext = 23,

  #[event(input = "ChatId", output = "ChatInfoPB")]
  GetChatInfo = 24,

  #[event(input = "ChatId", output = "ChatSettingsPB")]
  GetChatSettings = 25,

  #[event(input = "UpdateChatSettingsPB")]
  UpdateChatSettings = 26,

  #[event(input = "RegenerateResponsePB")]
  RegenerateResponse = 27,

  #[event(output = "AvailableModelsPB")]
  GetServerAvailableModels = 28,

  #[event(output = "LocalAISettingPB")]
  GetLocalAISetting = 29,

  #[event(input = "LocalAISettingPB")]
  UpdateLocalAISetting = 30,

  #[event(input = "AvailableModelsQueryPB", output = "AvailableModelsPB")]
  GetAvailableModels = 31,

  #[event(input = "UpdateSelectedModelPB")]
  UpdateSelectedModel = 32,

  #[event(output = "AvailableModelsPB")]
  GetLocalAIModels = 33,
}
