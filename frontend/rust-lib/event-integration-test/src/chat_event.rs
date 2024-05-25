use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;
use flowy_chat::entities::{
  ChatMessageListPB, ChatMessageTypePB, LoadChatMessagePB, SendChatPayloadPB,
};
use flowy_chat::event_map::ChatEvent;
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
      .event(ChatEvent::SendMessage)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn load_message(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> ChatMessageListPB {
    let payload = LoadChatMessagePB {
      chat_id: chat_id.to_string(),
      limit,
      after_message_id,
      before_message_id,
    };
    EventBuilder::new(self.clone())
      .event(ChatEvent::LoadMessage)
      .payload(payload)
      .async_send()
      .await
      .parse::<ChatMessageListPB>()
  }
}
