use std::sync::{Arc, Weak};
use tracing::instrument;
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
) -> Result<(), FlowyError> {
  let chat_manager = upgrade_chat_manager(chat_manager)?;
  let data = data.into_inner();
  data.validate()?;

  chat_manager
    .send_chat_message(&data.chat_id, &data.message)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn load_message_handler(
  data: AFPluginData<LoadChatMessagePB>,
  chat_manager: AFPluginState<Weak<ChatManager>>,
) -> DataResult<RepeatedChatMessagePB, FlowyError> {
  let chat_manager = upgrade_chat_manager(chat_manager)?;
  let data = data.into_inner();
  data.validate()?;

  let messages = chat_manager
    .load_chat_messages(
      &data.chat_id,
      data.limit,
      data.after_message_id,
      data.before_message_id,
    )
    .await?;
  data_result_ok(messages)
}
