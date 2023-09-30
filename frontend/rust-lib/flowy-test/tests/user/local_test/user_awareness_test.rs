use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::entities::{ReminderPB, RepeatedReminderPB};
use flowy_user::event_map::UserEvent::*;

#[tokio::test]
async fn user_update_with_name() {
  let sdk = FlowyCoreTest::new();
  let _ = sdk.sign_up_as_guest().await;
  let payload = ReminderPB {
    id: "".to_string(),
    scheduled_at: 0,
    is_ack: false,
    ty: 0,
    title: "".to_string(),
    message: "".to_string(),
    reminder_object_id: "".to_string(),
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
