use assert_json_diff::assert_json_eq;
use collab_plugins::cloud_storage::{CollabObject, CollabType};
use futures::future::join_all;
use serde_json::json;
use tokio::task;
use uuid::Uuid;
use yrs::types::ToJson;
use yrs::updates::decoder::Decode;
use yrs::{merge_updates_v1, Array, Doc, Map, MapPrelim, ReadTxn, StateVector, Transact, Update};

use flowy_user_deps::entities::SignUpResponse;
use lib_infra::box_any::BoxAny;

use crate::supabase_test::util::{
  collab_service, folder_service, get_supabase_config, sign_up_param, user_auth_service,
};

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

  // The init sync will try to merge the updates into one. Spawn 5 tasks to simulate
  // multiple clients trying to init sync at the same time.
  let mut handles = Vec::new();
  for _ in 0..5 {
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
  // after the init sync, the updates should be merged into one.
  let updates: Vec<Vec<u8>> = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap();
  assert_eq!(updates.len(), 1);
  // Other the init sync, try to get the updates from the server.
  let remote_update = updates.first().unwrap().clone();
  let expected_update = doc
    .transact_mut()
    .encode_state_as_update_v1(&StateVector::default());

  // check the update is the same as local document update.
  assert_eq!(remote_update, expected_update);
}

/// This async test function checks the behavior of updates duplication in Supabase.
/// It creates a new user and simulates two updates to the user's workspace with different values.
/// Then, it merges these updates and sends an initial synchronization request to test duplication handling.
/// Finally, it asserts that the duplicated updates don't affect the overall data consistency in Supabase.
#[tokio::test]
async fn supabase_duplicate_updates_test() {
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
  let mut duplicated_updates = vec![];
  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "1", "a");
    let update = txn.encode_update_v1();
    duplicated_updates.push(update.clone());
    collab_service
      .send_update(&collab_object, 0, update)
      .await
      .unwrap();
  };
  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "2", "b");
    let update = txn.encode_update_v1();
    duplicated_updates.push(update.clone());
    collab_service
      .send_update(&collab_object, 1, update)
      .await
      .unwrap();
  };
  // send init sync
  collab_service
    .send_init_sync(&collab_object, 3, vec![])
    .await
    .unwrap();
  let first_init_sync_update: Vec<u8> = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap()
    .first()
    .unwrap()
    .clone();

  // simulate the duplicated updates.
  let merged_update = merge_updates_v1(
    &duplicated_updates
      .iter()
      .map(|update| update.as_ref())
      .collect::<Vec<&[u8]>>(),
  )
  .unwrap();
  collab_service
    .send_init_sync(&collab_object, 4, merged_update)
    .await
    .unwrap();
  let second_init_sync_update: Vec<u8> = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap()
    .first()
    .unwrap()
    .clone();
  let doc_2 = Doc::new();
  assert_eq!(first_init_sync_update.len(), second_init_sync_update.len());
  let map = { doc_2.get_or_insert_map("map") };
  {
    let mut txn = doc_2.transact_mut();
    let update = Update::decode_v1(&second_init_sync_update).unwrap();
    txn.apply_update(update);
  }
  {
    let txn = doc_2.transact();
    let json = map.to_json(&txn);
    assert_json_eq!(
      json,
      json!({
        "1": "a",
        "2": "b"
      })
    );
  }
}

#[tokio::test]
async fn supabase_diff_state_vec_test() {
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
  let array = { doc.get_or_insert_array("array") };

  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "1", "a");
    map.insert(&mut txn, "inner_map", MapPrelim::<String>::new());

    array.push_back(&mut txn, "element 1");
    let update = txn.encode_update_v1();
    collab_service
      .send_update(&collab_object, 0, update)
      .await
      .unwrap();
  };
  {
    let mut txn = doc.transact_mut();
    map.insert(&mut txn, "2", "b");
    array.push_back(&mut txn, "element 2");
    let update = txn.encode_update_v1();
    collab_service
      .send_update(&collab_object, 1, update)
      .await
      .unwrap();
  };

  // restore the doc with given updates.
  let old_version_doc = Doc::new();
  let map = { old_version_doc.get_or_insert_map("map") };
  let updates: Vec<Vec<u8>> = folder_service
    .get_folder_updates(&user.latest_workspace.id, user.user_id)
    .await
    .unwrap();
  {
    let mut txn = old_version_doc.transact_mut();
    for update in updates {
      let update = Update::decode_v1(&update).unwrap();
      txn.apply_update(update);
    }
  }
  let txn = old_version_doc.transact();
  let json = map.to_json(&txn);
  assert_json_eq!(
    json,
    json!({
      "1": "a",
      "2": "b",
      "inner_map": {}
    })
  );
}
