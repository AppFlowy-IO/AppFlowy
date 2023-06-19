use crate::user::supabase_test::helper::get_supabase_config;
use flowy_folder2::entities::WorkspaceSettingPB;
use flowy_folder2::event_map::FolderEvent::GetCurrentWorkspace;

use flowy_test::{event_builder::EventBuilder, FlowyCoreTest};
use flowy_user::entities::{AuthTypePB, ThirdPartyAuthPB, UserProfilePB};

use flowy_user::event_map::UserEvent::*;
use std::collections::HashMap;

#[tokio::test]
async fn initial_workspace_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let mut map = HashMap::new();
    map.insert("uuid".to_string(), uuid::Uuid::new_v4().to_string());
    let payload = ThirdPartyAuthPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    let _ = EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>();

    let workspace_settings = EventBuilder::new(test.clone())
      .event(GetCurrentWorkspace)
      .async_send()
      .await
      .parse::<WorkspaceSettingPB>();

    assert!(workspace_settings.latest_view.is_some());
    dbg!(&workspace_settings);
  }
}
