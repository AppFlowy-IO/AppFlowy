use std::collections::HashMap;
use std::ops::Deref;

use flowy_server::supabase::SupabaseConfiguration;
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::entities::{
  AuthTypePB, ThirdPartyAuthPB, UserCredentialsPB, UserProfile, UserProfilePB,
};
use flowy_user::errors::{ErrorCode, FlowyError};
use flowy_user::event_map::UserEvent::{CheckUser, ThirdPartyAuth};

pub struct FlowySupabaseTest {
  inner: FlowyCoreTest,
}

impl FlowySupabaseTest {
  pub fn new() -> Option<Self> {
    dotenv::from_path(".env.test").ok()?;
    let _ = SupabaseConfiguration::from_env()?;
    let test = FlowyCoreTest::new();
    test.set_auth_type(AuthTypePB::Supabase);

    Some(Self { inner: test })
  }

  pub async fn check_user_with_uuid(&self, uuid: &str) -> Result<(), FlowyError> {
    match EventBuilder::new(test.clone())
      .event(CheckUser)
      .payload(UserCredentialsPB::from_uuid(uuid))
      .async_send()
      .await
      .error()
    {
      None => Ok(()),
      Some(error) => Err(error),
    }
  }

  pub async fn sign_up_with_uuid(&self, uuid: &str) -> UserProfilePB {
    let mut map = HashMap::new();
    map.insert("uuid".to_string(), uuid.to_string());
    let payload = ThirdPartyAuthPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>()
  }
}

impl Deref for FlowySupabaseTest {
  type Target = FlowyCoreTest;

  fn deref(&self) -> &Self::Target {
    &self.innerd
  }
}

/// In order to run this test, you need to create a .env file in the root directory of this project
/// and add the following environment variables:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
/// - SUPABASE_KEY
/// - SUPABASE_JWT_SECRET
///
/// the .env file should look like this:
/// SUPABASE_URL=https://<your-supabase-url>.supabase.co
/// SUPABASE_ANON_KEY=<your-supabase-anon-key>
/// SUPABASE_KEY=<your-supabase-key>
/// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
///
pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_path(".env.test").ok()?;
  SupabaseConfiguration::from_env().ok()
}

pub async fn init_supabase_test() -> Result<FlowyCoreTest, anyhow::Error> {
  dotenv::from_path(".env.test")?;
  let _ = SupabaseConfiguration::from_env()?;
  let uuid = "e71b7a69-803c-4327-b9bf-c47bb540e14f";
  let test = FlowyCoreTest::new();
  test.set_auth_type(AuthTypePB::Supabase);

  // check if the user already exists
  match EventBuilder::new(test.clone())
    .event(CheckUser)
    .payload(UserCredentialsPB::from_uuid(uuid))
    .async_send()
    .await
    .error()
  {
    None => {},
    Some(error) => {
      if error.code == ErrorCode::UserNotExist.value() {
        // create the user
        let mut map = HashMap::new();
        map.insert("uuid".to_string(), uuid.to_string());
        let payload = ThirdPartyAuthPB {
          map,
          auth_type: AuthTypePB::Supabase,
        };

        let _response = EventBuilder::new(test.clone())
          .event(ThirdPartyAuth)
          .payload(payload)
          .async_send()
          .await
          .parse::<UserProfilePB>();
      }
    },
  }

  Ok(test)
}

fn import_database_test_data() {}
