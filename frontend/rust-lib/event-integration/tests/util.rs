use std::fs::{create_dir_all, File};
use std::io::copy;
use std::ops::Deref;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use anyhow::Error;
use collab_folder::core::FolderData;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use nanoid::nanoid;
use tokio::sync::mpsc::Receiver;
use tokio::time::timeout;
use uuid::Uuid;
use zip::ZipArchive;

use event_integration::event_builder::EventBuilder;
use event_integration::Cleaner;
use event_integration::EventIntegrationTest;
use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_folder_deps::cloud::{FolderCloudService, FolderSnapshot};
use flowy_server::supabase::api::*;
use flowy_server::{AppFlowyEncryption, EncryptionImpl};
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;
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
  inner: EventIntegrationTest,
}

impl FlowySupabaseTest {
  pub fn new() -> Option<Self> {
    let _ = get_supabase_config()?;
    let test = EventIntegrationTest::new();
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
  type Target = EventIntegrationTest;

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

pub fn unzip_history_user_db(root: &str, folder_name: &str) -> std::io::Result<(Cleaner, PathBuf)> {
  // Open the zip file
  let zip_file_path = format!("{}/{}.zip", root, folder_name);
  let reader = File::open(zip_file_path)?;
  let output_folder_path = format!("{}/unit_test_{}", root, nanoid!(6));

  // Create a ZipArchive from the file
  let mut archive = ZipArchive::new(reader)?;

  // Iterate through each file in the zip
  for i in 0..archive.len() {
    let mut file = archive.by_index(i)?;
    let output_path = Path::new(&output_folder_path).join(file.mangled_name());

    if file.name().ends_with('/') {
      // Create directory
      create_dir_all(&output_path)?;
    } else {
      // Write file
      if let Some(p) = output_path.parent() {
        if !p.exists() {
          create_dir_all(p)?;
        }
      }
      let mut outfile = File::create(&output_path)?;
      copy(&mut file, &mut outfile)?;
    }
  }
  let path = format!("{}/{}", output_folder_path, folder_name);
  Ok((
    Cleaner::new(PathBuf::from(output_folder_path)),
    PathBuf::from(path),
  ))
}

pub struct AFCloudTest {
  inner: EventIntegrationTest,
}

impl AFCloudTest {
  pub fn new() -> Option<Self> {
    let _ = get_af_cloud_config()?;
    let test = EventIntegrationTest::new();
    test.set_auth_type(AuthTypePB::AFCloud);
    test.server_provider.set_auth_type(AuthType::AFCloud);

    Some(Self { inner: test })
  }
}

impl Deref for AFCloudTest {
  type Target = EventIntegrationTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub fn generate_test_email() -> String {
  format!("{}@test.com", Uuid::new_v4())
}

pub fn get_af_cloud_config() -> Option<AFCloudConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  AFCloudConfiguration::from_env().ok()
}
