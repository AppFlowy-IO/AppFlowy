use assert_json_diff::assert_json_eq;
use collab_entity::{CollabObject, CollabType};
use serde_json::json;
use uuid::Uuid;
use yrs::types::ToJson;
use yrs::updates::decoder::Decode;
use yrs::{merge_updates_v1, Array, Doc, Map, MapPrelim, ReadTxn, StateVector, Transact, Update};

use flowy_user_pub::entities::AuthResponse;
use lib_infra::box_any::BoxAny;

use crate::supabase_test::util::{
  collab_service, folder_service, get_supabase_ci_config, third_party_sign_up_param,
  user_auth_service,
};

#[tokio::test]
async fn supabase_create_workspace_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = folder_service();
  // will replace the uid with the real uid
  let workspace = service.create_workspace(1, "test").await.unwrap();
  dbg!(workspace);
}

#[tokio::test]
async fn supabase_get_folder_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let folder_service = folder_service();
  let user_service = user_auth_service();
  let collab_service = collab_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  let collab_object = CollabObject::new(
    user.user_id,
    user.latest_workspace.id.clone(),
    CollabType::Folder,
    user.latest_workspace.id.clone(),
    "fake_device_id".to_string(),
  );

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
    .get_folder_doc_state(
      &user.latest_workspace.id,
      user.user_id,
      CollabType::Folder,
      &user.latest_workspace.id,
    )
    .await
    .unwrap();
  assert_eq!(updates.len(), 2);

  for _ in 0..5 {
    collab_service
      .send_init_sync(&collab_object, 3, vec![])
      .await
      .unwrap();
  }
  let updates = folder_service
    .get_folder_doc_state(
      &user.latest_workspace.id,
      user.user_id,
      CollabType::Folder,
      &user.latest_workspace.id,
    )
    .await
    .unwrap();

  // Other the init sync, try to get the updates from the server.
  let expected_update = doc
    .transact_mut()
    .encode_state_as_update_v1(&StateVector::default());

  // check the update is the same as local document update.
  assert_eq!(updates, expected_update);
}

/// This async test function checks the behavior of updates duplication in Supabase.
/// It creates a new user and simulates two updates to the user's workspace with different values.
/// Then, it merges these updates and sends an initial synchronization request to test duplication handling.
/// Finally, it asserts that the duplicated updates don't affect the overall data consistency in Supabase.
#[tokio::test]
async fn supabase_duplicate_updates_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let folder_service = folder_service();
  let user_service = user_auth_service();
  let collab_service = collab_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  let collab_object = CollabObject::new(
    user.user_id,
    user.latest_workspace.id.clone(),
    CollabType::Folder,
    user.latest_workspace.id.clone(),
    "fake_device_id".to_string(),
  );
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
  let first_init_sync_update = folder_service
    .get_folder_doc_state(
      &user.latest_workspace.id,
      user.user_id,
      CollabType::Folder,
      &user.latest_workspace.id,
    )
    .await
    .unwrap();

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
  let second_init_sync_update = folder_service
    .get_folder_doc_state(
      &user.latest_workspace.id,
      user.user_id,
      CollabType::Folder,
      &user.latest_workspace.id,
    )
    .await
    .unwrap();

  let doc_2 = Doc::new();
  assert_eq!(first_init_sync_update.len(), second_init_sync_update.len());
  let map = { doc_2.get_or_insert_map("map") };
  {
    let mut txn = doc_2.transact_mut();
    let update = Update::decode_v1(&second_init_sync_update).unwrap();
    txn.apply_update(update).unwrap();
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

/// The state vector of doc;
/// ```json
///   "map": {},
///   "array": []
/// ```
/// The old version of doc:
/// ```json
///  "map": {}
/// ```
///
/// Try to apply the updates from doc to old version doc and check the result.
#[tokio::test]
async fn supabase_diff_state_vector_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let folder_service = folder_service();
  let user_service = user_auth_service();
  let collab_service = collab_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  let collab_object = CollabObject::new(
    user.user_id,
    user.latest_workspace.id.clone(),
    CollabType::Folder,
    user.latest_workspace.id.clone(),
    "fake_device_id".to_string(),
  );
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
  let doc_state = folder_service
    .get_folder_doc_state(
      &user.latest_workspace.id,
      user.user_id,
      CollabType::Folder,
      &user.latest_workspace.id,
    )
    .await
    .unwrap();
  {
    let mut txn = old_version_doc.transact_mut();
    let update = Update::decode_v1(&doc_state).unwrap();
    txn.apply_update(update).unwrap();
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

// #[tokio::test]
// async fn print_folder_object_test() {
//   if get_supabase_dev_config().is_none() {
//     return;
//   }
//   let secret = Some("43bSxEPHeNkk5ZxxEYOfAjjd7sK2DJ$vVnxwuNc5ru0iKFvhs8wLg==".to_string());
//   print_encryption_folder("f8b14b84-e8ec-4cf4-a318-c1e008ecfdfa", secret).await;
// }
//
// #[tokio::test]
// async fn print_folder_snapshot_object_test() {
//   if get_supabase_dev_config().is_none() {
//     return;
//   }
//   let secret = Some("NTXRXrDSybqFEm32jwMBDzbxvCtgjU$8np3TGywbBdJAzHtu1QIyQ==".to_string());
//   // let secret = None;
//   print_encryption_folder_snapshot("12533251-bdd4-41f4-995f-ff12fceeaa42", secret).await;
// }
