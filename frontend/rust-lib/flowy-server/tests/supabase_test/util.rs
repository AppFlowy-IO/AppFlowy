use crate::setup_log;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_server::supabase::storage_impls::restful_api::{
  RESTfulPostgresServer, RESTfulSupabaseCollabStorageImpl, RESTfulSupabaseDatabaseServiceImpl,
};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use std::sync::Arc;

pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.test").ok()?;
  setup_log();
  SupabaseConfiguration::from_env().ok()
}

pub fn collab_service() -> Arc<dyn RemoteCollabStorage> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseCollabStorageImpl::new(server.postgrest))
}

pub fn database_service() -> Arc<dyn DatabaseCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseDatabaseServiceImpl::new(server.postgrest))
}
