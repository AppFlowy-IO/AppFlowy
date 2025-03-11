use std::fs;
use std::path::PathBuf;

use crate::ai_manager::AIManager;
use crate::completion::AICompletion;
use crate::entities::*;
use flowy_ai_pub::cloud::{ChatMessageMetadata, ChatMessageType, ChatRAGData, ContextLoader};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use serde_json::json;
use std::sync::{Arc, Weak};
use tracing::trace;
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
    metadata,
  } = data;

  let message_type = match message_type {
    ChatMessageTypePB::System => ChatMessageType::System,
    ChatMessageTypePB::User => ChatMessageType::User,
  };

  let metadata = metadata
    .into_iter()
    .map(|metadata| {
      let (content_type, content_len) = match metadata.loader_type {
        ContextLoaderTypePB::Txt => (ContextLoader::Text, metadata.data.len()),
        ContextLoaderTypePB::Markdown => (ContextLoader::Markdown, metadata.data.len()),
        ContextLoaderTypePB::PDF => (ContextLoader::PDF, 0),
        ContextLoaderTypePB::UnknownLoaderType => (ContextLoader::Unknown, 0),
      };

      ChatMessageMetadata {
        data: ChatRAGData {
          content: metadata.data,
          content_type,
          size: content_len as i64,
        },
        id: metadata.id,
        name: metadata.name.clone(),
        source: metadata.source,
        extra: None,
      }
    })
    .collect::<Vec<_>>();

  trace!("Stream chat message with metadata: {:?}", metadata);

  let params = StreamMessageParams {
    chat_id: &chat_id,
    message: &message,
    message_type,
    answer_stream_port,
    question_stream_port,
    format,
    metadata,
  };

  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let result = ai_manager.stream_chat_message(&params).await?;
  data_result_ok(result)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn regenerate_response_handler(
  data: AFPluginData<RegenerateResponsePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> FlowyResult<()> {
  let data = data.try_into_inner()?;

  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager
    .stream_regenerate_response(
      &data.chat_id,
      data.answer_message_id,
      data.answer_stream_port,
      data.format,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_model_list_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ModelConfigPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let available_models = ai_manager.get_available_models().await?;
  let models = available_models
    .models
    .into_iter()
    .map(|m| m.name)
    .collect::<Vec<String>>();

  let models = serde_json::to_string(&json!({"models": models}))?;
  data_result_ok(ModelConfigPB { models })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn load_prev_message_handler(
  data: AFPluginData<LoadPrevChatMessagePB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessageListPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let messages = ai_manager
    .load_prev_chat_messages(&data.chat_id, data.limit, data.before_message_id)
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

  let messages = ai_manager
    .load_latest_chat_messages(&data.chat_id, data.limit, data.after_message_id)
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
  let messages = ai_manager
    .get_related_questions(&data.chat_id, data.message_id)
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
  let message = ai_manager
    .generate_answer(&data.chat_id, data.message_id)
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
  ai_manager.stop_stream(&data.chat_id).await?;
  Ok(())
}

pub(crate) async fn start_complete_text_handler(
  data: AFPluginData<CompleteTextPB>,
  tools: AFPluginState<Arc<AICompletion>>,
) -> DataResult<CompleteTextTaskPB, FlowyError> {
  let task = tools.create_complete_task(data.into_inner()).await?;
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
  ai_manager.chat_with_file(&data.chat_id, file_path).await?;
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
  let _ = ai_manager.local_ai.toggle_local_ai().await?;
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
pub(crate) async fn get_offline_app_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIAppLinkPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let link = ai_manager.local_ai.get_plugin_download_link().await?;
  data_result_ok(LocalAIAppLinkPB { link })
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
  ai_manager
    .update_rag_ids(&params.chat_id.value, params.rag_ids)
    .await?;

  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_local_ai_setting_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAISettingPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let setting = ai_manager.local_ai.get_local_ai_setting();
  let pb = LocalAISettingPB::from(setting);
  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_local_ai_setting_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
  data: AFPluginData<LocalAISettingPB>,
) -> Result<(), FlowyError> {
  let data = data.try_into_inner()?;
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager
    .local_ai
    .update_local_ai_setting(data.into())
    .await?;
  Ok(())
}
