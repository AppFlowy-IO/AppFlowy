use std::sync::Arc;

use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::{merge_updates_v1, Update};
use collab_document::blocks::DocumentData;
use collab_document::document::Document;

use flowy_document2::entities::{DocumentDataPB, OpenDocumentPayloadPB};
use flowy_document2::event_map::DocumentEvent;
use flowy_folder2::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder2::event_map::FolderEvent;

use crate::document::document_event::{DocumentEventTest, OpenDocumentData};
use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  pub async fn create_document(
    &self,
    parent_id: &str,
    name: String,
    initial_data: Vec<u8>,
  ) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Document,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };
    let view = EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>();

    let payload = OpenDocumentPayloadPB {
      document_id: view.id.clone(),
    };

    let _ = EventBuilder::new(self.clone())
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();

    view
  }
  pub async fn open_document(&self, doc_id: String) -> OpenDocumentData {
    let payload = OpenDocumentPayloadPB {
      document_id: doc_id.clone(),
    };
    let data = EventBuilder::new(self.clone())
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();
    OpenDocumentData { id: doc_id, data }
  }
  pub async fn insert_document_text(&self, document_id: &str, text: &str, index: usize) {
    let document_event = DocumentEventTest::new_with_core(self.clone());
    document_event
      .insert_index(document_id, text, index, None)
      .await;
  }

  pub async fn get_document_data(&self, view_id: &str) -> DocumentData {
    let pb = EventBuilder::new(self.clone())
      .event(DocumentEvent::GetDocumentData)
      .payload(OpenDocumentPayloadPB {
        document_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<DocumentDataPB>();

    DocumentData::from(pb)
  }

  pub async fn get_document_update(&self, document_id: &str) -> Vec<u8> {
    let workspace_id = self.user_manager.workspace_id().unwrap();
    let cloud_service = self.document_manager.get_cloud_service().clone();
    let remote_updates = cloud_service
      .get_document_updates(document_id, &workspace_id)
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

pub fn assert_document_data_equal(collab_update: &[u8], doc_id: &str, expected: DocumentData) {
  let collab = MutexCollab::new(CollabOrigin::Server, doc_id, vec![]);
  collab.lock().with_origin_transact_mut(|txn| {
    let update = Update::decode_v1(collab_update).unwrap();
    txn.apply_update(update);
  });
  let document = Document::open(Arc::new(collab)).unwrap();
  let actual = document.get_document_data().unwrap();
  assert_eq!(actual, expected);
}
