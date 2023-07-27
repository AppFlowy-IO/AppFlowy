use crate::supabase_test::util::get_supabase_config;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server::supabase::storage_impls::restful_api::{
  RESTfulPostgresServer, RESTfulSupabaseFolderServiceImpl,
};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use std::sync::Arc;

#[tokio::test]
async fn supabase_create_workspace_test() {
  if get_supabase_config().is_none() {
    return;
  }

  let service = folder_service();
  // will replace the uid with the real uid
  let workspace = service.create_workspace(2, "test").await.unwrap();
  dbg!(workspace);
}

fn folder_service() -> Arc<dyn FolderCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseFolderServiceImpl::new(server.postgrest))
}
