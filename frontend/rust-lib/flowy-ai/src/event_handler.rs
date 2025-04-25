use crate::ai_manager::{AIManager, GLOBAL_ACTIVE_MODEL_KEY};
use crate::completion::AICompletion;
use crate::entities::*;
use flowy_ai_pub::cloud::{AIModel, ChatMessageType};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use std::fs;
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use uuid::Uuid;
use validator::Validate;

fn upgrade_ai_manager(ai_manager: AFPluginState<Weak<AIManager>>) -> FlowyResult<Arc<AIManager>> {
  let ai_manager = ai_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The chat manager is already dropped"))?;
  Ok(ai_manager)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn stream_chat_message_handler(
  data: AFPluginData<StreamChatPayloadPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessagePB, FlowyError> {
  let data = data.into_inner();
  data.validate()?;

  let StreamChatPayloadPB {
    chat_id,
    message,
    message_type,
    answer_stream_port,
    question_stream_port,
    format,
  } = data;

  let message_type = match message_type {
    ChatMessageTypePB::System => ChatMessageType::System,
    ChatMessageTypePB::User => ChatMessageType::User,
  };

  let chat_id = Uuid::from_str(&chat_id)?;
  let params = StreamMessageParams {
    chat_id,
    message,
    message_type,
    answer_stream_port,
    question_stream_port,
    format,
  };

  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let result = ai_manager.stream_chat_message(params).await?;
  data_result_ok(result)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn regenerate_response_handler(
  data: AFPluginData<RegenerateResponsePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> FlowyResult<()> {
  let data = data.try_into_inner()?;
  let chat_id = Uuid::from_str(&data.chat_id)?;

  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager
    .stream_regenerate_response(
      &chat_id,
      data.answer_message_id,
      data.answer_stream_port,
      data.format,
      data.model,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_server_model_list_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<AvailableModelsPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let models = ai_manager
    .get_available_models(GLOBAL_ACTIVE_MODEL_KEY.to_string())
    .await?;
  data_result_ok(models)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_chat_models_handler(
  data: AFPluginData<AvailableModelsQueryPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<AvailableModelsPB, FlowyError> {
  let data = data.try_into_inner()?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let models = ai_manager.get_available_models(data.source).await?;
  data_result_ok(models)
}

pub(crate) async fn update_selected_model_handler(
  data: AFPluginData<UpdateSelectedModelPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager
    .update_selected_model(data.source, AIModel::from(data.selected_model))
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn load_prev_message_handler(
  data: AFPluginData<LoadPrevChatMessagePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessageListPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let chat_id = Uuid::from_str(&data.chat_id)?;
  let messages = ai_manager
    .load_prev_chat_messages(&chat_id, data.limit as u64, data.before_message_id)
    .await?;
  data_result_ok(messages)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn load_next_message_handler(
  data: AFPluginData<LoadNextChatMessagePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessageListPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let chat_id = Uuid::from_str(&data.chat_id)?;
  let messages = ai_manager
    .load_latest_chat_messages(&chat_id, data.limit as u64, data.after_message_id)
    .await?;
  data_result_ok(messages)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_related_question_handler(
  data: AFPluginData<ChatMessageIdPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<RepeatedRelatedQuestionPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  let chat_id = Uuid::from_str(&data.chat_id)?;
  let messages = ai_manager
    .get_related_questions(&chat_id, data.message_id)
    .await?;
  data_result_ok(messages)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_answer_handler(
  data: AFPluginData<ChatMessageIdPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessagePB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  let chat_id = Uuid::from_str(&data.chat_id)?;
  let message = ai_manager
    .generate_answer(&chat_id, data.message_id)
    .await?;
  data_result_ok(message)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn stop_stream_handler(
  data: AFPluginData<StopStreamPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  data.validate()?;

  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let chat_id = Uuid::from_str(&data.chat_id)?;
  ai_manager.stop_stream(&chat_id).await?;
  Ok(())
}

pub(crate) async fn start_complete_text_handler(
  data: AFPluginData<CompleteTextPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
  tools: AFPluginState<Arc<AICompletion>>,
) -> DataResult<CompleteTextTaskPB, FlowyError> {
  let data = data.into_inner();
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let ai_model = ai_manager.get_active_model(&data.object_id).await;
  let task = tools.create_complete_task(data, ai_model).await?;
  data_result_ok(task)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn stop_complete_text_handler(
  data: AFPluginData<CompleteTextTaskPB>,
  tools: AFPluginState<Arc<AICompletion>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  tools.cancel_complete_task(&data.task_id).await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn chat_file_handler(
  data: AFPluginData<ChatFilePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let file_path = PathBuf::from(&data.file_path);

  let allowed_extensions = ["pdf", "md", "txt"];
  let extension = file_path
    .extension()
    .and_then(|ext| ext.to_str())
    .ok_or_else(|| {
      FlowyError::new(
        ErrorCode::UnsupportedFileFormat,
        "Can't find file extension",
      )
    })?;

  if !allowed_extensions.contains(&extension) {
    return Err(FlowyError::new(
      ErrorCode::UnsupportedFileFormat,
      "Only support pdf,md and txt",
    ));
  }
  let file_size = fs::metadata(&file_path)
    .map_err(|_| {
      FlowyError::new(
        ErrorCode::UnsupportedFileFormat,
        "Failed to get file metadata",
      )
    })?
    .len();

  const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024;
  if file_size > MAX_FILE_SIZE {
    return Err(FlowyError::new(
      ErrorCode::PayloadTooLarge,
      "File size is too large. Max file size is 10MB",
    ));
  }

  tracing::debug!("File size: {} bytes", file_size);
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let chat_id = Uuid::from_str(&data.chat_id)?;
  ai_manager.chat_with_file(&chat_id, file_path).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn restart_local_ai_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager.local_ai.restart_plugin().await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn toggle_local_ai_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager.toggle_local_ai().await?;
  let state = ai_manager.local_ai.get_local_ai_state().await;
  data_result_ok(state)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_local_ai_state_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let state = ai_manager.local_ai.get_local_ai_state().await;
  data_result_ok(state)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn create_chat_context_handler(
  data: AFPluginData<CreateChatContextPB>,
  _ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let _data = data.try_into_inner()?;

  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_chat_info_handler(
  data: AFPluginData<ChatId>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatInfoPB, FlowyError> {
  let chat_id = data.try_into_inner()?.value;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let pb = ai_manager.get_chat_info(&chat_id).await?;
  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_chat_settings_handler(
  data: AFPluginData<ChatId>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatSettingsPB, FlowyError> {
  let chat_id = data.try_into_inner()?.value;
  let chat_id = Uuid::from_str(&chat_id)?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let rag_ids = ai_manager.get_rag_ids(&chat_id).await?;
  let pb = ChatSettingsPB { rag_ids };
  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_chat_settings_handler(
  data: AFPluginData<UpdateChatSettingsPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> FlowyResult<()> {
  let params = data.try_into_inner()?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let chat_id = Uuid::from_str(&params.chat_id.value)?;
  ai_manager.update_rag_ids(&chat_id, params.rag_ids).await?;

  Ok(())
}

#[tracing::instrument(level = "debug", skip_all)]
pub(crate) async fn get_local_ai_setting_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAISettingPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let setting = ai_manager.local_ai.get_local_ai_setting();
  let pb = LocalAISettingPB::from(setting);
  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all)]
pub(crate) async fn get_local_ai_models_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<AvailableModelsPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = ai_manager.get_local_available_models().await?;
  data_result_ok(data)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_local_ai_setting_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
  data: AFPluginData<LocalAISettingPB>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager.update_local_ai_setting(data.into()).await?;
  Ok(())
}
