use crate::util::FlowySupabaseTest;

use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::Update;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use flowy_document2::entities::{
  DocumentDataPB, DocumentSnapshotPB, OpenDocumentPayloadPB, RepeatedDocumentSnapshotPB,
};
use flowy_document2::event_map::DocumentEvent::{GetDocumentData, GetDocumentSnapshots};
use flowy_folder2::entities::ViewPB;
use flowy_test::event_builder::EventBuilder;
use std::ops::Deref;
use std::sync::Arc;

pub struct FlowySupabaseDocumentTest {
  inner: FlowySupabaseTest,
}

impl FlowySupabaseDocumentTest {
  pub async fn new() -> Option<Self> {
    let inner = FlowySupabaseTest::new()?;
    let uuid = uuid::Uuid::new_v4().to_string();
    let _ = inner.sign_up_with_uuid(&uuid).await;
    Some(Self { inner })
  }

  pub async fn create_document(&self) -> ViewPB {
    let current_workspace = self.inner.get_current_workspace().await;
    self
      .inner
      .create_document(&current_workspace.workspace.id, "my document", vec![])
      .await
  }

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

  pub async fn get_document_data(&self, view_id: &str) -> DocumentData {
    let pb = EventBuilder::new(self.inner.deref().clone())
      .event(GetDocumentData)
      .payload(OpenDocumentPayloadPB {
        document_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<DocumentDataPB>();

    DocumentData::from(pb)
  }
}

impl Deref for FlowySupabaseDocumentTest {
  type Target = FlowySupabaseTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub fn assert_document_snapshot_equal(
  snapshot: &DocumentSnapshotPB,
  doc_id: &str,
  expected: DocumentData,
) {
  let collab = MutexCollab::new(CollabOrigin::Server, doc_id, vec![]);
  collab.lock().with_transact_mut(|txn| {
    let update = Update::decode_v1(&snapshot.data).unwrap();
    txn.apply_update(update);
  });
  let document = Document::open(Arc::new(collab)).unwrap();
  let actual = document.get_document_data().unwrap();
  assert_eq!(actual, expected);
}
