use collab_plugins::cloud_storage::{CollabObject, CollabType};
use uuid::Uuid;

use flowy_user_deps::entities::SignUpResponse;
use lib_infra::box_any::BoxAny;

use crate::supabase_test::util::{
  collab_service, database_service, get_supabase_ci_config, third_party_sign_up_param,
  user_auth_service,
};

#[tokio::test]
async fn supabase_create_workspace_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  let collab_service = collab_service();
  let database_service = database_service();

  let mut row_ids = vec![];
  for _i in 0..3 {
    let row_id = uuid::Uuid::new_v4().to_string();
    row_ids.push(row_id.clone());
    let collab_object = CollabObject {
      object_id: row_id,
      uid: user.user_id,
      ty: CollabType::DatabaseRow,
      meta: Default::default(),
    }
    .with_workspace_id(user.latest_workspace.id.clone());
    collab_service
      .send_update(&collab_object, 0, vec![1, 2, 3])
      .await
      .unwrap();
    collab_service
      .send_update(&collab_object, 0, vec![4, 5, 6])
      .await
      .unwrap();
  }

  let updates_by_oid = database_service
    .batch_get_collab_updates(row_ids, CollabType::DatabaseRow)
    .await
    .unwrap();

  assert_eq!(updates_by_oid.len(), 3);
  for (_, update) in updates_by_oid {
    assert_eq!(update.len(), 2);
  }
}
