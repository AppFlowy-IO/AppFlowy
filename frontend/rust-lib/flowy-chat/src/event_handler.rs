use flowy_chat_pub::cloud::ChatMessageType;
use std::sync::{Arc, Weak};
use validator::Validate;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::entities::*;
use crate::manager::ChatManager;

fn upgrade_chat_manager(
  chat_manager: AFPluginState<Weak<ChatManager>>,
) -> FlowyResult<Arc<ChatManager>> {
  let chat_manager = chat_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The chat manager is already dropped"))?;
  Ok(chat_manager)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn send_chat_message_handler(
  data: AFPluginData<SendChatPayloadPB>,
  chat_manager: AFPluginState<Weak<ChatManager>>,
) -> DataResult<RepeatedChatMessagePB, FlowyError> {
  let chat_manager = upgrade_chat_manager(chat_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let message_type = match data.message_type {
    ChatMessageTypePB::System => ChatMessageType::System,
    ChatMessageTypePB::User => ChatMessageType::User,
  };
  let messages = chat_manager
    .send_chat_message(&data.chat_id, &data.message, message_type)
    .await?;

  data_result_ok(RepeatedChatMessagePB::from(messages))
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn load_message_handler(
  data: AFPluginData<LoadChatMessagePB>,
  chat_manager: AFPluginState<Weak<ChatManager>>,
) -> DataResult<ChatMessageListPB, FlowyError> {
  let chat_manager = upgrade_chat_manager(chat_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let messages = chat_manager
    .load_prev_chat_messages(&data.chat_id, data.limit, data.before_message_id)
    .await?;
  data_result_ok(messages)
}
