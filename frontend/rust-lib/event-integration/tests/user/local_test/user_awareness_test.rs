use std::collections::HashMap;

use event_integration::event_builder::EventBuilder;
use event_integration::EventIntegrationTest;
use flowy_user::entities::{ReminderPB, RepeatedReminderPB};
use flowy_user::event_map::UserEvent::*;

#[tokio::test]
async fn user_update_with_reminder() {
  let sdk = EventIntegrationTest::new().await;
  let _ = sdk.sign_up_as_guest().await;
  let mut meta = HashMap::new();
  meta.insert("object_id".to_string(), "".to_string());

  let payload = ReminderPB {
    id: "".to_string(),
    scheduled_at: 0,
    is_ack: false,
    is_read: false,
    title: "".to_string(),
    message: "".to_string(),
    object_id: "".to_string(),
    meta,
  };

  let _ = EventBuilder::new(sdk.clone())
    .event(CreateReminder)
    .payload(payload)
    .async_send()
    .await;

  let reminders = EventBuilder::new(sdk.clone())
    .event(GetAllReminders)
    .async_send()
    .await
    .parse::<RepeatedReminderPB>()
    .items;

  assert_eq!(reminders.len(), 1);
}
