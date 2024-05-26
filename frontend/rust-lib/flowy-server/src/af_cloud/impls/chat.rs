use crate::af_cloud::AFServer;
use client_api::entity::{
  CreateChatMessageParams, CreateChatParams, MessageCursor, RepeatedChatMessage,
};
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessageStream, ChatMessageType};
use flowy_error::FlowyError;
use futures_util::StreamExt;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub(crate) struct AFCloudChatCloudServiceImpl<T> {
  pub inner: T,
}

#[async_trait]
impl<T> ChatCloudService for AFCloudChatCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_chat(
    &self,
    _uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let params = CreateChatParams {
        chat_id,
        name: "".to_string(),
        rag_ids: vec![],
      };
      try_get_client?
        .create_chat(&workspace_id, params)
        .await
        .map_err(FlowyError::from)?;

      Ok(())
    })
  }

  async fn send_chat_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessageStream, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let message = message.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatMessageParams {
      content: message,
      message_type,
    };
    let stream = try_get_client?
      .create_chat_message(&workspace_id, &chat_id, params)
      .await
      .map_err(FlowyError::from)?;

    Ok(stream.boxed())
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let resp = try_get_client?
        .get_chat_messages(&workspace_id, &chat_id, offset, limit)
        .await
        .map_err(FlowyError::from)?;

      Ok(resp)
    })
  }
}
