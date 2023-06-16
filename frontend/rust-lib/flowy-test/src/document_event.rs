use crate::event_builder::EventBuilder;
use crate::FlowyCoreTest;
use flowy_document2::entities::*;
use flowy_document2::event_map::DocumentEvent;
use flowy_folder2::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder2::event_map::FolderEvent;

pub struct DocumentEventTest {
  inner: FlowyCoreTest,
}

pub struct OpenDocumentData {
  pub id: String,
  pub data: DocumentDataPB,
}

impl DocumentEventTest {
  pub async fn new() -> Self {
    let sdk = FlowyCoreTest::new_with_user().await;
    Self { inner: sdk }
  }

  pub async fn create_document(&self) -> ViewPB {
    let core = &self.inner;
    let current_workspace = core.get_current_workspace().await.workspace;
    let parent_id = current_workspace.id.clone();

    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name: "document".to_string(),
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Document,
      initial_data: vec![],
      meta: Default::default(),
      set_as_current: true,
    };
    EventBuilder::new(core.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn open_document(&self, doc_id: String) -> OpenDocumentData {
    let core = &self.inner;
    let payload = OpenDocumentPayloadPB {
      document_id: doc_id.clone(),
    };
    let data = EventBuilder::new(core.clone())
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();
    OpenDocumentData { id: doc_id, data }
  }

  pub async fn apply_actions(&self, payload: ApplyActionPayloadPB) {
    let core = &self.inner;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ApplyAction)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn undo(&self, doc_id: String) -> DocumentRedoUndoResponsePB {
    let core = &self.inner;
    let payload = DocumentRedoUndoPayloadPB {
      document_id: doc_id.clone(),
    };
    EventBuilder::new(core.clone())
      .event(DocumentEvent::Undo)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentRedoUndoResponsePB>()
  }

  pub async fn redo(&self, doc_id: String) -> DocumentRedoUndoResponsePB {
    let core = &self.inner;
    let payload = DocumentRedoUndoPayloadPB {
      document_id: doc_id.clone(),
    };
    EventBuilder::new(core.clone())
      .event(DocumentEvent::Redo)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentRedoUndoResponsePB>()
  }

  pub async fn can_undo_redo(&self, doc_id: String) -> DocumentRedoUndoResponsePB {
    let core = &self.inner;
    let payload = DocumentRedoUndoPayloadPB {
      document_id: doc_id.clone(),
    };
    EventBuilder::new(core.clone())
      .event(DocumentEvent::CanUndoRedo)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentRedoUndoResponsePB>()
  }
}
