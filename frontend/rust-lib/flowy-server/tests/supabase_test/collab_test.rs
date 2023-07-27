use crate::supabase_test::util::get_supabase_config;
use collab_plugins::cloud_storage::{CollabObject, CollabType, RemoteCollabStorage};
use flowy_server::supabase::storage_impls::restful_api::{
  RESTfulPostgresServer, RESTfulSupabaseCollabStorageImpl,
};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use std::sync::Arc;
use uuid::Uuid;

#[tokio::test]
async fn supabase_send_collab_update_test() {
  if get_supabase_config().is_none() {
    return;
  }

  let uuid = Uuid::new_v4().to_string();
  // will replace the uid with the real workspace_id
  let workspace_id = "a0f9c2c8-8054-4e8c-944a-cc2c164418ce";
  let collab_object = CollabObject {
    id: uuid,
    uid: 1,
    ty: CollabType::Document,
    meta: Default::default(),
  }
  .with_workspace_id(workspace_id.to_string());

  let service = collab_service();
  service
    .send_update(&collab_object, 0, vec![1, 2, 3])
    .await
    .unwrap();

  let _updates = service.get_all_updates(&collab_object).await.unwrap();
}

fn collab_service() -> Arc<dyn RemoteCollabStorage> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseCollabStorageImpl::new(server.postgrest))
}
