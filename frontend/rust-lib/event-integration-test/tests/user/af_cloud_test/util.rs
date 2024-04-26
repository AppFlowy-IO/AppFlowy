use std::time::Duration;

use event_integration::EventIntegrationTest;
use flowy_user::{
  entities::{RepeatedUserWorkspacePB, UserWorkspacePB},
  protobuf::UserNotification,
};

use crate::util::receive_with_timeout;

pub async fn get_synced_workspaces(
  test: &EventIntegrationTest,
  user_id: i64,
) -> Vec<UserWorkspacePB> {
  let _workspaces = test.get_all_workspaces().await.items;
  let sub_id = user_id.to_string();
  let rx = test
    .notification_sender
    .subscribe::<RepeatedUserWorkspacePB>(
      &sub_id,
      UserNotification::DidUpdateUserWorkspaces as i32,
    );
  receive_with_timeout(rx, Duration::from_secs(60))
    .await
    .unwrap()
    .items
}
