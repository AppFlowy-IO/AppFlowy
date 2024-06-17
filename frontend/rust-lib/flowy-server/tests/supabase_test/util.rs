use std::collections::HashMap;
use std::sync::Arc;

use collab::core::collab::{DataSource, MutexCollab};
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use uuid::Uuid;

use flowy_database_pub::cloud::DatabaseCloudService;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{Folder, FolderCloudService};
use flowy_server::supabase::api::{
  RESTfulPostgresServer, SupabaseCollabStorageImpl, SupabaseDatabaseServiceImpl,
  SupabaseFolderServiceImpl, SupabaseServerServiceImpl, SupabaseUserServiceImpl,
};
use flowy_server::supabase::define::{USER_DEVICE_ID, USER_EMAIL, USER_UUID};
use flowy_server::{AppFlowyEncryption, EncryptionImpl};
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_user_pub::cloud::UserCloudService;
use lib_infra::future::FutureResult;

use crate::setup_log;

pub fn get_supabase_ci_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  setup_log();
  SupabaseConfiguration::from_env().ok()
}

#[allow(dead_code)]
pub fn get_supabase_dev_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.dev").ok()?;
  setup_log();
  SupabaseConfiguration::from_env().ok()
}

pub fn collab_service() -> Arc<dyn RemoteCollabStorage> {
  let (server, encryption_impl) = supabase_server_service(None);
  Arc::new(SupabaseCollabStorageImpl::new(
    server,
    None,
    Arc::downgrade(&encryption_impl),
  ))
}

pub fn database_service() -> Arc<dyn DatabaseCloudService> {
  let (server, _encryption_impl) = supabase_server_service(None);
  Arc::new(SupabaseDatabaseServiceImpl::new(server))
}

pub fn user_auth_service() -> Arc<dyn UserCloudService> {
  let (server, _encryption_impl) = supabase_server_service(None);
  Arc::new(SupabaseUserServiceImpl::new(server, vec![], None))
}

pub fn folder_service() -> Arc<dyn FolderCloudService> {
  let (server, _encryption_impl) = supabase_server_service(None);
  Arc::new(SupabaseFolderServiceImpl::new(server))
}

#[allow(dead_code)]
pub fn file_storage_service() -> Arc<dyn ObjectStorageCloudService> {
  let encryption_impl: Arc<dyn AppFlowyEncryption> = Arc::new(EncryptionImpl::new(None));
  let config = SupabaseConfiguration::from_env().unwrap();
  Arc::new(
    SupabaseFileStorage::new(
      &config,
      Arc::downgrade(&encryption_impl),
      Arc::new(TestFileStoragePlan),
    )
    .unwrap(),
  )
}

#[allow(dead_code)]
pub fn encryption_folder_service(
  secret: Option<String>,
) -> (Arc<dyn FolderCloudService>, Arc<dyn AppFlowyEncryption>) {
  let (server, encryption_impl) = supabase_server_service(secret);
  let service = Arc::new(SupabaseFolderServiceImpl::new(server));
  (service, encryption_impl)
}

#[allow(dead_code)]
pub fn encryption_collab_service(
  secret: Option<String>,
) -> (Arc<dyn RemoteCollabStorage>, Arc<dyn AppFlowyEncryption>) {
  let (server, encryption_impl) = supabase_server_service(secret);
  let service = Arc::new(SupabaseCollabStorageImpl::new(
    server,
    None,
    Arc::downgrade(&encryption_impl),
  ));
  (service, encryption_impl)
}

#[allow(dead_code)]
pub async fn print_encryption_folder(
  uid: &i64,
  folder_id: &str,
  encryption_secret: Option<String>,
) {
  let (cloud_service, _encryption) = encryption_folder_service(encryption_secret);
  let folder_data = cloud_service.get_folder_data(folder_id, uid).await.unwrap();
  let json = serde_json::to_value(folder_data).unwrap();
  println!("{}", serde_json::to_string_pretty(&json).unwrap());
}

#[allow(dead_code)]
pub async fn print_encryption_folder_snapshot(
  uid: &i64,
  folder_id: &str,
  encryption_secret: Option<String>,
) {
  let (cloud_service, _encryption) = encryption_collab_service(encryption_secret);
  let snapshot = cloud_service
    .get_snapshots(folder_id, 1)
    .await
    .pop()
    .unwrap();
  let collab = Arc::new(MutexCollab::new(
    Collab::new_with_source(
      CollabOrigin::Empty,
      folder_id,
      DataSource::DocStateV1(snapshot.blob),
      vec![],
      false,
    )
    .unwrap(),
  ));
  let folder_data = Folder::open(uid, collab, None)
    .unwrap()
    .get_folder_data(folder_id)
    .unwrap();
  let json = serde_json::to_value(folder_data).unwrap();
  println!("{}", serde_json::to_string_pretty(&json).unwrap());
}

pub fn supabase_server_service(
  encryption_secret: Option<String>,
) -> (SupabaseServerServiceImpl, Arc<dyn AppFlowyEncryption>) {
  let config = SupabaseConfiguration::from_env().unwrap();
  let encryption_impl: Arc<dyn AppFlowyEncryption> =
    Arc::new(EncryptionImpl::new(encryption_secret));
  let encryption = Arc::downgrade(&encryption_impl);
  let server = Arc::new(RESTfulPostgresServer::new(config, encryption));
  (SupabaseServerServiceImpl::new(server), encryption_impl)
}

pub fn third_party_sign_up_param(uuid: String) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid);
  params.insert(
    USER_EMAIL.to_string(),
    format!("{}@test.com", Uuid::new_v4()),
  );
  params.insert(USER_DEVICE_ID.to_string(), Uuid::new_v4().to_string());
  params
}

pub struct TestFileStoragePlan;
