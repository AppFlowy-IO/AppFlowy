use client_api::entity::{MessageOffset, RepeatedChatMessage};
use flowy_chat_pub::cloud::ChatCloudService;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct DefaultChatCloudServiceImpl;

impl ChatCloudService for DefaultChatCloudServiceImpl {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  fn send_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageOffset,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }
}
