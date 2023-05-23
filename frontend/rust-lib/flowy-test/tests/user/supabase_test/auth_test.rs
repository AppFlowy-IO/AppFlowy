use crate::user::supabase_test::helper::get_supabase_config;

use flowy_test::{event_builder::EventBuilder, FlowyCoreTest};
use flowy_user::entities::{AuthTypePB, ThirdPartyAuthPB, UserProfilePB};

use flowy_user::event_map::UserEvent::*;
use std::collections::HashMap;

#[tokio::test]
async fn sign_up_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let mut map = HashMap::new();
    map.insert("uuid".to_string(), uuid::Uuid::new_v4().to_string());
    let payload = ThirdPartyAuthPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    let response = EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>();
    dbg!(&response);
  }
}
