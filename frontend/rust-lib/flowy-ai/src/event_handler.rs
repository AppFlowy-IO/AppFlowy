use flowy_ai_pub::cloud::ChatMessageType;

use std::path::PathBuf;

use allo_isolate::Isolate;
use std::sync::{Arc, Weak};
use tokio::sync::oneshot;
use validator::Validate;

use crate::ai_manager::AIManager;
use crate::completion::AICompletion;
use crate::entities::*;
use crate::local_ai::local_llm_chat::LLMModelInfo;
use crate::notification::{make_notification, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use lib_infra::isolate_stream::IsolateSink;

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
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let message_type = match data.message_type {
    ChatMessageTypePB::System => ChatMessageType::System,
    ChatMessageTypePB::User => ChatMessageType::User,
  };

  let question = ai_manager
    .stream_chat_message(
      &data.chat_id,
      &data.message,
      message_type,
      data.text_stream_port,
    )
    .await?;
  data_result_ok(question)
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
  let (tx, rx) = tokio::sync::oneshot::channel();
  tokio::spawn(async move {
    let messages = ai_manager
      .get_related_questions(&data.chat_id, data.message_id)
      .await?;
    let _ = tx.send(messages);
    Ok::<_, FlowyError>(())
  });
  let messages = rx.await?;
  data_result_ok(messages)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_answer_handler(
  data: AFPluginData<ChatMessageIdPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<ChatMessagePB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let data = data.into_inner();
  let (tx, rx) = tokio::sync::oneshot::channel();
  tokio::spawn(async move {
    let message = ai_manager
      .generate_answer(&data.chat_id, data.message_id)
      .await?;
    let _ = tx.send(message);
    Ok::<_, FlowyError>(())
  });
  let message = rx.await?;
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

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn refresh_local_ai_info_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LLMModelInfoPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let (tx, rx) = oneshot::channel::<Result<LLMModelInfo, FlowyError>>();
  tokio::spawn(async move {
    let model_info = ai_manager.local_ai_controller.refresh().await;
    if model_info.is_err() {
      if let Some(llm_model) = ai_manager.local_ai_controller.get_current_model() {
        let model_info = LLMModelInfo {
          selected_model: llm_model.clone(),
          models: vec![llm_model],
        };
        let _ = tx.send(Ok(model_info));
        return;
      }
    }

    let _ = tx.send(model_info);
  });

  let model_info = rx.await??;
  data_result_ok(model_info.into())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_local_llm_model_handler(
  data: AFPluginData<LLMModelPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalModelResourcePB, FlowyError> {
  let data = data.into_inner();
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let state = ai_manager
    .local_ai_controller
    .select_local_llm(data.llm_id)
    .await?;
  data_result_ok(state)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_local_llm_state_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalModelResourcePB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let state = ai_manager.local_ai_controller.get_local_llm_state().await?;
  data_result_ok(state)
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

  let (tx, rx) = oneshot::channel::<Result<(), FlowyError>>();
  tokio::spawn(async move {
    let ai_manager = upgrade_ai_manager(ai_manager)?;
    ai_manager.chat_with_file(&data.chat_id, file_path).await?;
    let _ = tx.send(Ok(()));
    Ok::<_, FlowyError>(())
  });

  rx.await?
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn download_llm_resource_handler(
  data: AFPluginData<DownloadLLMPB>,
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<DownloadTaskPB, FlowyError> {
  let data = data.into_inner();
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let text_sink = IsolateSink::new(Isolate::new(data.progress_stream));
  let task_id = ai_manager
    .local_ai_controller
    .start_downloading(text_sink)
    .await?;
  data_result_ok(DownloadTaskPB { task_id })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn cancel_download_llm_resource_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager.local_ai_controller.cancel_download()?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_plugin_state_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIPluginStatePB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let state = ai_manager.local_ai_controller.get_chat_plugin_state();
  data_result_ok(state)
}
#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn toggle_local_ai_chat_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIChatPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let enabled = ai_manager
    .local_ai_controller
    .toggle_local_ai_chat()
    .await?;
  let file_enabled = ai_manager.local_ai_controller.is_rag_enabled();
  let plugin_state = ai_manager.local_ai_controller.get_chat_plugin_state();
  let pb = LocalAIChatPB {
    enabled,
    file_enabled,
    plugin_state,
  };
  make_notification(
    APPFLOWY_AI_NOTIFICATION_KEY,
    ChatNotification::UpdateLocalChatAI,
  )
  .payload(pb.clone())
  .send();
  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn toggle_local_ai_chat_file_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIChatPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let enabled = ai_manager.local_ai_controller.is_chat_enabled();
  let file_enabled = ai_manager
    .local_ai_controller
    .toggle_local_ai_chat_rag()
    .await?;
  let plugin_state = ai_manager.local_ai_controller.get_chat_plugin_state();
  let pb = LocalAIChatPB {
    enabled,
    file_enabled,
    plugin_state,
  };
  make_notification(
    APPFLOWY_AI_NOTIFICATION_KEY,
    ChatNotification::UpdateLocalChatAI,
  )
  .payload(pb.clone())
  .send();

  data_result_ok(pb)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_local_ai_chat_state_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIChatPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let enabled = ai_manager.local_ai_controller.is_chat_enabled();
  let file_enabled = ai_manager.local_ai_controller.is_rag_enabled();
  let plugin_state = ai_manager.local_ai_controller.get_chat_plugin_state();
  data_result_ok(LocalAIChatPB {
    enabled,
    file_enabled,
    plugin_state,
  })
}
#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn restart_local_ai_chat_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> Result<(), FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  ai_manager.local_ai_controller.restart_chat_plugin();
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn toggle_local_ai_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let enabled = ai_manager.local_ai_controller.toggle_local_ai().await?;
  data_result_ok(LocalAIPB { enabled })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_local_ai_state_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalAIPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let enabled = ai_manager.local_ai_controller.is_enabled();
  data_result_ok(LocalAIPB { enabled })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_model_storage_directory_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<LocalModelStoragePB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let file_path = ai_manager
    .local_ai_controller
    .get_model_storage_directory()?;
  data_result_ok(LocalModelStoragePB { file_path })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_offline_app_handler(
  ai_manager: AFPluginState<Weak<AIManager>>,
) -> DataResult<OfflineAIPB, FlowyError> {
  let ai_manager = upgrade_ai_manager(ai_manager)?;
  let (tx, rx) = oneshot::channel::<Result<String, FlowyError>>();
  tokio::spawn(async move {
    let link = ai_manager
      .local_ai_controller
      .get_offline_ai_app_download_link()
      .await?;
    let _ = tx.send(Ok(link));
    Ok::<_, FlowyError>(())
  });

  let link = rx.await??;
  data_result_ok(OfflineAIPB { link })
}
