use std::ops::Deref;

use event_integration::event_builder::EventBuilder;
use flowy_document::entities::{OpenDocumentPayloadPB, RepeatedDocumentSnapshotMetaPB};
use flowy_document::event_map::DocumentEvent::GetDocumentSnapshotMeta;
use flowy_folder::entities::ViewPB;

use crate::util::FlowySupabaseTest;

pub struct FlowySupabaseDocumentTest {
  inner: FlowySupabaseTest,
}

impl FlowySupabaseDocumentTest {
  pub async fn new() -> Option<Self> {
    let inner = FlowySupabaseTest::new().await?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.supabase_sign_up_with_uuid(&uuid, None).await;
    Some(Self { inner })
  }

  pub async fn create_document(&self) -> ViewPB {
    let current_workspace = self.inner.get_current_workspace().await;
    self
      .inner
      .create_and_open_document(&current_workspace.id, "my document".to_string(), vec![])
      .await
  }

  #[allow(dead_code)]
  pub async fn get_document_snapshots(&self, view_id: &str) -> RepeatedDocumentSnapshotMetaPB {
    EventBuilder::new(self.inner.deref().clone())
      .event(GetDocumentSnapshotMeta)
      .payload(OpenDocumentPayloadPB {
        document_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedDocumentSnapshotMetaPB>()
  }
}

impl Deref for FlowySupabaseDocumentTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}
