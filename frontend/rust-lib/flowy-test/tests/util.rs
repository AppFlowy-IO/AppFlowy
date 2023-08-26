use std::ops::Deref;
use std::sync::Arc;
use std::time::Duration;

use anyhow::Error;
use collab_folder::core::FolderData;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use tokio::sync::mpsc::Receiver;
use tokio::time::timeout;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_folder_deps::cloud::{FolderCloudService, FolderSnapshot};
use flowy_server::supabase::api::*;
use flowy_server::{AppFlowyEncryption, EncryptionImpl};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::entities::{AuthTypePB, UpdateUserProfilePayloadPB, UserCredentialsPB};
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user::event_map::UserEvent::*;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::AuthType;

pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_path(".env.ci").ok()?;
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

  pub async fn update_user_profile(
    &self,
    payload: UpdateUserProfilePayloadPB,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.inner.clone())
      .event(UpdateUserProfile)
      .payload(payload)
      .async_send()
      .await
      .error()
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

pub fn get_supabase_ci_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  SupabaseConfiguration::from_env().ok()
}

#[allow(dead_code)]
pub fn get_supabase_dev_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.dev").ok()?;
  SupabaseConfiguration::from_env().ok()
}

pub fn collab_service() -> Arc<dyn RemoteCollabStorage> {
  let (server, encryption_impl) = appflowy_server(None);
  Arc::new(SupabaseCollabStorageImpl::new(
    server,
    None,
    Arc::downgrade(&encryption_impl),
  ))
}

pub fn database_service() -> Arc<dyn DatabaseCloudService> {
  let (server, _encryption_impl) = appflowy_server(None);
  Arc::new(SupabaseDatabaseServiceImpl::new(server))
}

pub fn user_auth_service() -> Arc<dyn UserCloudService> {
  let (server, _encryption_impl) = appflowy_server(None);
  Arc::new(SupabaseUserServiceImpl::new(server, vec![], None))
}

pub fn folder_service() -> Arc<dyn FolderCloudService> {
  let (server, _encryption_impl) = appflowy_server(None);
  Arc::new(SupabaseFolderServiceImpl::new(server))
}

#[allow(dead_code)]
pub fn encryption_folder_service(
  secret: Option<String>,
) -> (Arc<dyn FolderCloudService>, Arc<dyn AppFlowyEncryption>) {
  let (server, encryption_impl) = appflowy_server(secret);
  let service = Arc::new(SupabaseFolderServiceImpl::new(server));
  (service, encryption_impl)
}

pub fn encryption_collab_service(
  secret: Option<String>,
) -> (Arc<dyn RemoteCollabStorage>, Arc<dyn AppFlowyEncryption>) {
  let (server, encryption_impl) = appflowy_server(secret);
  let service = Arc::new(SupabaseCollabStorageImpl::new(
    server,
    None,
    Arc::downgrade(&encryption_impl),
  ));
  (service, encryption_impl)
}

pub async fn get_folder_data_from_server(
  folder_id: &str,
  encryption_secret: Option<String>,
) -> Result<Option<FolderData>, Error> {
  let (cloud_service, _encryption) = encryption_folder_service(encryption_secret);
  cloud_service.get_folder_data(folder_id).await
}

pub async fn get_folder_snapshots(
  folder_id: &str,
  encryption_secret: Option<String>,
) -> Vec<FolderSnapshot> {
  let (cloud_service, _encryption) = encryption_folder_service(encryption_secret);
  cloud_service
    .get_folder_snapshots(folder_id, 10)
    .await
    .unwrap()
}

pub fn appflowy_server(
  encryption_secret: Option<String>,
) -> (SupabaseServerServiceImpl, Arc<dyn AppFlowyEncryption>) {
  let config = SupabaseConfiguration::from_env().unwrap();
  let encryption_impl: Arc<dyn AppFlowyEncryption> =
    Arc::new(EncryptionImpl::new(encryption_secret));
  let encryption = Arc::downgrade(&encryption_impl);
  let server = Arc::new(RESTfulPostgresServer::new(config, encryption));
  (SupabaseServerServiceImpl::new(server), encryption_impl)
}
