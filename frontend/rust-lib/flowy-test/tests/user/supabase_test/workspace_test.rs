use std::collections::HashMap;

use flowy_folder2::entities::WorkspaceSettingPB;
use flowy_folder2::event_map::FolderEvent::GetCurrentWorkspace;
use flowy_server::supabase::define::{USER_EMAIL, USER_UUID};
use flowy_test::{event_builder::EventBuilder, FlowyCoreTest};
use flowy_user::entities::{AuthTypePB, OauthSignInPB, UserProfilePB};
use flowy_user::event_map::UserEvent::*;

use crate::util::*;

#[tokio::test]
async fn initial_workspace_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid::Uuid::new_v4().to_string());
    map.insert(
      USER_EMAIL.to_string(),
      format!("{}@gmail.com", uuid::Uuid::new_v4()),
    );
    let payload = OauthSignInPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    let _ = EventBuilder::new(test.clone())
      .event(OauthSignIn)
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
