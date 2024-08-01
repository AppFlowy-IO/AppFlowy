use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;
use flowy_ai::entities::{
  ChatMessageListPB, ChatMessageTypePB, CompleteTextPB, CompleteTextTaskPB, CompletionTypePB,
  LoadNextChatMessagePB, LoadPrevChatMessagePB, SendChatPayloadPB,
};
use flowy_ai::event_map::AIEvent;
use flowy_folder::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder::event_map::FolderEvent;

impl EventIntegrationTest {
  pub async fn create_chat(&self, parent_id: &str) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name: "chat".to_string(),
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Chat,
      initial_data: vec![],
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
      view_id: None,
      extra: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn send_message(
    &self,
    chat_id: &str,
    message: impl ToString,
    message_type: ChatMessageTypePB,
  ) {
    let payload = SendChatPayloadPB {
      chat_id: chat_id.to_string(),
      message: message.to_string(),
      message_type,
    };

    EventBuilder::new(self.clone())
      .event(AIEvent::StreamMessage)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn load_prev_message(
    &self,
    chat_id: &str,
    limit: i64,
    before_message_id: Option<i64>,
  ) -> ChatMessageListPB {
    let payload = LoadPrevChatMessagePB {
      chat_id: chat_id.to_string(),
      limit,
      before_message_id,
    };
    EventBuilder::new(self.clone())
      .event(AIEvent::LoadPrevMessage)
      .payload(payload)
      .async_send()
      .await
      .parse::<ChatMessageListPB>()
  }

  pub async fn load_next_message(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
  ) -> ChatMessageListPB {
    let payload = LoadNextChatMessagePB {
      chat_id: chat_id.to_string(),
      limit,
      after_message_id,
    };
    EventBuilder::new(self.clone())
      .event(AIEvent::LoadNextMessage)
      .payload(payload)
      .async_send()
      .await
      .parse::<ChatMessageListPB>()
  }

  pub async fn complete_text(
    &self,
    text: &str,
    completion_type: CompletionTypePB,
  ) -> CompleteTextTaskPB {
    let payload = CompleteTextPB {
      text: text.to_string(),
      completion_type,
      stream_port: 0,
    };
    EventBuilder::new(self.clone())
      .event(AIEvent::CompleteText)
      .payload(payload)
      .async_send()
      .await
      .parse::<CompleteTextTaskPB>()
  }
}
