use std::ops::Deref;

use assert_json_diff::assert_json_eq;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::{Collab, JsonValue, Update};
use collab_entity::CollabType;

use event_integration_test::event_builder::EventBuilder;
use flowy_database2::entities::{DatabasePB, DatabaseViewIdPB, RepeatedDatabaseSnapshotPB};
use flowy_database2::event_map::DatabaseEvent::*;
use flowy_folder::entities::ViewPB;

use crate::util::FlowySupabaseTest;

pub struct FlowySupabaseDatabaseTest {
  pub uuid: String,
  inner: FlowySupabaseTest,
}

impl FlowySupabaseDatabaseTest {
  #[allow(dead_code)]
  pub async fn new_with_user(uuid: String) -> Option<Self> {
    let inner = FlowySupabaseTest::new().await?;
    inner.supabase_sign_up_with_uuid(&uuid, None).await.unwrap();
    Some(Self { uuid, inner })
  }

  pub async fn new_with_new_user() -> Option<Self> {
    let inner = FlowySupabaseTest::new().await?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.supabase_sign_up_with_uuid(&uuid, None).await.unwrap();
    Some(Self { uuid, inner })
  }

  pub async fn create_database(&self) -> (ViewPB, DatabasePB) {
    let current_workspace = self.inner.get_current_workspace().await;
    let view = self
      .inner
      .create_grid(&current_workspace.id, "my database".to_string(), vec![])
      .await;
    let database = self.inner.get_database(&view.id).await;
    (view, database)
  }

  pub async fn get_collab_json(&self, database_id: &str) -> JsonValue {
    let database_editor = self
      .database_manager
      .get_database(database_id)
      .await
      .unwrap();
    // let address = Arc::into_raw(database_editor.clone());
    let database = database_editor.get_mutex_database().lock();
    database.get_mutex_collab().to_json_value()
  }

  pub async fn get_database_snapshots(&self, view_id: &str) -> RepeatedDatabaseSnapshotPB {
    EventBuilder::new(self.inner.deref().clone())
      .event(GetDatabaseSnapshots)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedDatabaseSnapshotPB>()
  }

  pub async fn get_database_collab_update(&self, database_id: &str) -> Vec<u8> {
    let workspace_id = self.user_manager.workspace_id().unwrap();
    let cloud_service = self.database_manager.get_cloud_service().clone();
    cloud_service
      .get_database_object_doc_state(database_id, CollabType::Database, &workspace_id)
      .await
      .unwrap()
      .unwrap()
  }
}

pub fn assert_database_collab_content(
  database_id: &str,
  collab_update: &[u8],
  expected: JsonValue,
) {
  let collab = MutexCollab::new(Collab::new_with_origin(
    CollabOrigin::Server,
    database_id,
    vec![],
    false,
  ));
  collab.lock().with_origin_transact_mut(|txn| {
    let update = Update::decode_v1(collab_update).unwrap();
    txn.apply_update(update).unwrap();
  });

  let json = collab.to_json_value();
  assert_json_eq!(json, expected);
}

impl Deref for FlowySupabaseDatabaseTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
