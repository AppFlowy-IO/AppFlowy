use crate::supabase_test::user_test::{sign_up_param, user_auth_service};
use crate::supabase_test::util::{collab_service, get_supabase_config};
use collab_plugins::cloud_storage::{CollabObject, CollabType};
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server::supabase::storage_impls::restful_api::{
  RESTfulPostgresServer, RESTfulSupabaseFolderServiceImpl,
};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_user_deps::entities::SignUpResponse;
use futures::future::join_all;
use lib_infra::box_any::BoxAny;
use std::sync::Arc;
use tokio::task;
use uuid::Uuid;
use yrs::{Doc, Map, ReadTxn, StateVector, Transact};

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

  let folder_service = folder_service();
  let user_service = user_auth_service();
  let collab_service = collab_service();
  let uuid = Uuid::new_v4().to_string();
  let params = sign_up_param(uuid);
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  let collab_object = CollabObject {
    id: user.latest_workspace.id.clone(),
    uid: user.user_id,
    ty: CollabType::Folder,
    meta: Default::default(),
  }
  .with_workspace_id(user.latest_workspace.id.clone());

  let doc = Doc::with_client_id(1);
  let map = { doc.get_or_insert_map("map") };
  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "1", "a");
    collab_service
      .send_update(&collab_object, 0, txn.encode_update_v1())
      .await
      .unwrap();
  };

  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "2", "b");
    collab_service
      .send_update(&collab_object, 1, txn.encode_update_v1())
      .await
      .unwrap();
  };

  // let updates = collab_service.get_all_updates(&collab_object).await.unwrap();
  let updates = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap();
  assert_eq!(updates.len(), 2);

  // The init sync will try to merge the updates into one.
  let mut handles = Vec::new();
  for _ in 0..10 {
    let cloned_collab_service = collab_service.clone();
    let cloned_collab_object = collab_object.clone();
    let handle = task::spawn(async move {
      cloned_collab_service
        .send_init_sync(&cloned_collab_object, 3, vec![])
        .await
        .unwrap();
    });
    handles.push(handle);
  }
  let _results: Vec<_> = join_all(handles).await;
  let remote_update = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap()
    .first()
    .unwrap()
    .clone();
  let expected_update = doc
    .transact_mut()
    .encode_state_as_update_v1(&StateVector::default());

  // check the update is the same as local document update.
  assert_eq!(remote_update, expected_update);
}

fn folder_service() -> Arc<dyn FolderCloudService> {
  let config = SupabaseConfiguration::from_env().unwrap();
  let server = RESTfulPostgresServer::new(config);
  Arc::new(RESTfulSupabaseFolderServiceImpl::new(server.postgrest))
}
