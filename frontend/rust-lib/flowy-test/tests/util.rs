use std::ops::Deref;
use std::time::Duration;

use tokio::sync::mpsc::Receiver;
use tokio::time::timeout;

use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::entities::{
  AuthTypePB, UpdateUserProfilePayloadPB, UserCredentialsPB, UserProfilePB,
};
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user::event_map::UserEvent::*;
use flowy_user::services::AuthType;

/// In order to run this test, you need to create a .env.test file in the root directory of this project
/// and add the following environment variables:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
/// - SUPABASE_KEY
/// - SUPABASE_JWT_SECRET
/// - SUPABASE_DB
/// - SUPABASE_DB_USER
/// - SUPABASE_DB_PORT
/// - SUPABASE_DB_PASSWORD
///
/// the .env.test file should look like this:
/// SUPABASE_URL=https://<your-supabase-url>.supabase.co
/// SUPABASE_ANON_KEY=<your-supabase-anon-key>
/// SUPABASE_KEY=<your-supabase-key>
/// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
/// SUPABASE_DB=db.xxx.supabase.co
/// SUPABASE_DB_USER=<your-supabase-db-user>
/// SUPABASE_DB_PORT=<your-supabase-db-port>
/// SUPABASE_DB_PASSWORD=<your-supabase-db-password>
///
pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_path(".env.test").ok()?;
  SupabaseConfiguration::from_env().ok()
}

pub struct FlowySupabaseTest {
  inner: FlowyCoreTest,
}

impl FlowySupabaseTest {
  pub fn new() -> Option<Self> {
    let _ = get_supabase_config()?;
    let test = FlowyCoreTest::new();
    test.set_auth_type(AuthTypePB::Supabase);
    test.server_provider.set_auth_type(AuthType::Supabase);

    Some(Self { inner: test })
  }

  pub async fn check_user_with_uuid(&self, uuid: &str) -> Result<(), FlowyError> {
    match EventBuilder::new(self.inner.clone())
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

  pub async fn get_user_profile(&self) -> Result<UserProfilePB, FlowyError> {
    EventBuilder::new(self.inner.clone())
      .event(GetUserProfile)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()
  }

  pub async fn update_user_profile(&self, payload: UpdateUserProfilePayloadPB) {
    EventBuilder::new(self.inner.clone())
      .event(UpdateUserProfile)
      .payload(payload)
      .async_send()
      .await;
  }
}

impl Deref for FlowySupabaseTest {
  type Target = FlowyCoreTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub async fn receive_with_timeout<T>(
  receiver: &mut Receiver<T>,
  duration: Duration,
) -> Result<T, Box<dyn std::error::Error>> {
  let res = timeout(duration, receiver.recv())
    .await?
    .ok_or(anyhow::anyhow!("recv timeout"))?;
  Ok(res)
}
