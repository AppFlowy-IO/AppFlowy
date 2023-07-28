use std::collections::HashMap;
use std::sync::Arc;

use collab_plugins::cloud_storage::RemoteCollabStorage;
use uuid::Uuid;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server::supabase::api::{
  RESTfulPostgresServer, RESTfulSupabaseCollabStorageImpl, RESTfulSupabaseDatabaseServiceImpl,
  RESTfulSupabaseFolderServiceImpl, RESTfulSupabaseUserAuthServiceImpl, SupabaseServerServiceImpl,
};
use flowy_server::supabase::define::{USER_EMAIL, USER_UUID};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_user_deps::cloud::UserService;

use crate::setup_log;

pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.test").ok()?;
  setup_log();
  SupabaseConfiguration::from_env().ok()
}

pub fn collab_service() -> Arc<dyn RemoteCollabStorage> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = Arc::new(RESTfulPostgresServer::new(config));
  Arc::new(RESTfulSupabaseCollabStorageImpl::new(
    SupabaseServerServiceImpl::new(server),
  ))
}

pub fn database_service() -> Arc<dyn DatabaseCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = Arc::new(RESTfulPostgresServer::new(config));
  Arc::new(RESTfulSupabaseDatabaseServiceImpl::new(
    SupabaseServerServiceImpl::new(server),
  ))
}

pub fn user_auth_service() -> Arc<dyn UserService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = Arc::new(RESTfulPostgresServer::new(config));
  Arc::new(RESTfulSupabaseUserAuthServiceImpl::new(
    SupabaseServerServiceImpl::new(server),
  ))
}

pub fn folder_service() -> Arc<dyn FolderCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = Arc::new(RESTfulPostgresServer::new(config));
  Arc::new(RESTfulSupabaseFolderServiceImpl::new(
    SupabaseServerServiceImpl::new(server),
  ))
}

pub fn sign_up_param(uuid: String) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid);
  params.insert(
    USER_EMAIL.to_string(),
    format!("{}@test.com", Uuid::new_v4()),
  );
  params
}
