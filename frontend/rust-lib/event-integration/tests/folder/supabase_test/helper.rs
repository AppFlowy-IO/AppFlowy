use std::ops::Deref;

use assert_json_diff::assert_json_eq;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::{merge_updates_v1, JsonValue, Update};
use collab_folder::FolderData;

use event_integration::event_builder::EventBuilder;
use flowy_folder2::entities::{FolderSnapshotPB, RepeatedFolderSnapshotPB, WorkspaceIdPB};
use flowy_folder2::event_map::FolderEvent::GetFolderSnapshots;

use crate::util::FlowySupabaseTest;

pub struct FlowySupabaseFolderTest {
  inner: FlowySupabaseTest,
}

impl FlowySupabaseFolderTest {
  pub async fn new() -> Option<Self> {
    let inner = FlowySupabaseTest::new().await?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.supabase_sign_up_with_uuid(&uuid, None).await;
    Some(Self { inner })
  }

  pub async fn get_collab_json(&self) -> JsonValue {
    let folder = self.folder_manager.get_mutex_folder().lock();
    folder.as_ref().unwrap().to_json_value()
  }

  pub async fn get_local_folder_data(&self) -> FolderData {
    let folder = self.folder_manager.get_mutex_folder().lock();
    folder.as_ref().unwrap().get_folder_data().unwrap()
  }

  pub async fn get_folder_snapshots(&self, workspace_id: &str) -> Vec<FolderSnapshotPB> {
    EventBuilder::new(self.inner.deref().clone())
      .event(GetFolderSnapshots)
      .payload(WorkspaceIdPB {
        value: workspace_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedFolderSnapshotPB>()
      .items
  }

  pub async fn get_collab_update(&self, workspace_id: &str) -> Vec<u8> {
    let cloud_service = self.folder_manager.get_cloud_service().clone();
    let remote_updates = cloud_service
      .get_folder_doc_state(workspace_id, self.user_manager.user_id().unwrap())
      .await
      .unwrap();

    if remote_updates.is_empty() {
      return vec![];
    }

    let updates = remote_updates
      .iter()
      .map(|update| update.as_ref())
      .collect::<Vec<&[u8]>>();

    merge_updates_v1(&updates).unwrap()
  }
}

pub fn assert_folder_collab_content(workspace_id: &str, collab_update: &[u8], expected: JsonValue) {
  if collab_update.is_empty() {
    panic!("collab update is empty");
  }

  let collab = MutexCollab::new(CollabOrigin::Server, workspace_id, vec![]);
  collab.lock().with_origin_transact_mut(|txn| {
    let update = Update::decode_v1(collab_update).unwrap();
    txn.apply_update(update);
  });

  let json = collab.to_json_value();
  assert_json_eq!(json["folder"], expected);
}

impl Deref for FlowySupabaseFolderTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
