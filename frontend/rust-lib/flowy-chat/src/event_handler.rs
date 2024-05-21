use std::sync::{Arc, Weak};
use tracing::instrument;

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

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn send_chat_message_handler(
  data: AFPluginData<SendChatPayloadPB>,
  folder: AFPluginState<Weak<ChatManager>>,
) -> Result<(), FlowyError> {
  Ok(())
}
