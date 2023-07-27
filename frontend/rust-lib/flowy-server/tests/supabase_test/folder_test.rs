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
  let workspace = service.create_workspace(1, "test").await.unwrap();
  dbg!(workspace);
}

#[tokio::test]
async fn supabase_get_folder_test() {
  if get_supabase_config().is_none() {
    return;
  }

  let service = folder_service();
  let workspace_id = "a0f9c2c8-8054-4e8c-944a-cc2c164418ce";
  // will replace the uid with the real workspace_id
  let folder = service.get_folder_data(workspace_id).await.unwrap();
  assert!(folder.is_some());

  let _updates = service.get_folder_updates(workspace_id, 2).await.unwrap();
}

#[tokio::test]
async fn supabase_get_folder_snapshot_test() {
  if get_supabase_config().is_none() {
    return;
  }

  let service = folder_service();
  // will replace the uid with the real workspace_id
  let workspace_id = "a0f9c2c8-8054-4e8c-944a-cc2c164418ce";
  let snapshot = service
    .get_folder_latest_snapshot(workspace_id)
    .await
    .unwrap();
  assert!(snapshot.is_some());
}

fn folder_service() -> Arc<dyn FolderCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseFolderServiceImpl::new(server.postgrest))
}
