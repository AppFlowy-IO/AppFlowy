use std::ops::Deref;

use collab::preclude::merge_updates_v1;

use flowy_document2::entities::{OpenDocumentPayloadPB, RepeatedDocumentSnapshotPB};
use flowy_document2::event_map::DocumentEvent::GetDocumentSnapshots;
use flowy_folder2::entities::ViewPB;
use flowy_test::event_builder::EventBuilder;

use crate::util::FlowySupabaseTest;

pub struct FlowySupabaseDocumentTest {
  inner: FlowySupabaseTest,
}

impl FlowySupabaseDocumentTest {
  pub async fn new() -> Option<Self> {
    let inner = FlowySupabaseTest::new()?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.supabase_sign_up_with_uuid(&uuid, None).await;
    Some(Self { inner })
  }

  pub async fn create_document(&self) -> ViewPB {
    let current_workspace = self.inner.get_current_workspace().await;
    self
      .inner
      .create_document(
        &current_workspace.workspace.id,
        "my document".to_string(),
        vec![],
      )
      .await
  }

  #[allow(dead_code)]
  pub async fn get_document_snapshots(&self, view_id: &str) -> RepeatedDocumentSnapshotPB {
    EventBuilder::new(self.inner.deref().clone())
      .event(GetDocumentSnapshots)
      .payload(OpenDocumentPayloadPB {
        document_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedDocumentSnapshotPB>()
  }

  pub async fn get_document_update(&self, document_id: &str) -> Vec<u8> {
    let cloud_service = self.document_manager.get_cloud_service().clone();
    let remote_updates = cloud_service
      .get_document_updates(document_id)
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

impl Deref for FlowySupabaseDocumentTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
