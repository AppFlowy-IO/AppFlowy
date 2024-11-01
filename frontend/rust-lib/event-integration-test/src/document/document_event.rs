use collab::entity::EncodedCollab;
use std::collections::HashMap;

use serde_json::Value;

use flowy_document::entities::*;
use flowy_document::event_map::DocumentEvent;
use flowy_document::parser::parser_entities::{
  ConvertDataToJsonPayloadPB, ConvertDataToJsonResponsePB, ConvertDocumentPayloadPB,
  ConvertDocumentResponsePB,
};
use flowy_folder::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder::event_map::FolderEvent;

use crate::document::utils::{gen_delta_str, gen_id, gen_text_block_data};
use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

const TEXT_BLOCK_TY: &str = "paragraph";

pub struct DocumentEventTest {
  event_test: EventIntegrationTest,
}

pub struct OpenDocumentData {
  pub id: String,
  pub data: DocumentDataPB,
}

impl DocumentEventTest {
  pub async fn new() -> Self {
    let sdk = EventIntegrationTest::new_anon().await;
    Self { event_test: sdk }
  }

  pub fn new_with_core(core: EventIntegrationTest) -> Self {
    Self { event_test: core }
  }

  pub async fn get_encoded_v1(&self, doc_id: &str) -> EncodedCollab {
    let doc = self
      .event_test
      .appflowy_core
      .document_manager
      .editable_document(doc_id)
      .await
      .unwrap();
    let guard = doc.read().await;
    guard.encode_collab().unwrap()
  }

  pub async fn get_encoded_collab(&self, doc_id: &str) -> EncodedCollabPB {
    let core = &self.event_test;
    let payload = OpenDocumentPayloadPB {
      document_id: doc_id.to_string(),
    };
    EventBuilder::new(core.clone())
      .event(DocumentEvent::GetDocEncodedCollab)
      .payload(payload)
      .async_send()
      .await
      .parse::<EncodedCollabPB>()
  }

  pub async fn create_document(&self) -> ViewPB {
    let core = &self.event_test;
    let current_workspace = core.get_current_workspace().await;
    let parent_id = current_workspace.id.clone();

    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name: "document".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Document,
      initial_data: vec![],
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
      view_id: None,
      extra: None,
    };
    EventBuilder::new(core.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn open_document(&self, doc_id: String) -> OpenDocumentData {
    self.event_test.open_document(doc_id).await
  }

  pub async fn get_block(&self, doc_id: &str, block_id: &str) -> Option<BlockPB> {
    let document_data = self.event_test.open_document(doc_id.to_string()).await;
    document_data.data.blocks.get(block_id).cloned()
  }

  pub async fn get_page_id(&self, doc_id: &str) -> String {
    let data = self.get_document_data(doc_id).await;
    data.page_id
  }

  pub async fn get_document_data(&self, doc_id: &str) -> DocumentDataPB {
    let document_data = self.event_test.open_document(doc_id.to_string()).await;
    document_data.data
  }

  pub async fn get_block_children(&self, doc_id: &str, block_id: &str) -> Option<Vec<String>> {
    let block = self.get_block(doc_id, block_id).await;
    block.as_ref()?;
    let document_data = self.get_document_data(doc_id).await;
    let children_map = document_data.meta.children_map;
    let children_id = block.unwrap().children_id;
    children_map.get(&children_id).map(|c| c.children.clone())
  }

  pub async fn get_text_id(&self, doc_id: &str, block_id: &str) -> Option<String> {
    let block = self.get_block(doc_id, block_id).await?;
    block.external_id
  }

  pub async fn get_delta(&self, doc_id: &str, text_id: &str) -> Option<String> {
    let document_data = self.get_document_data(doc_id).await;
    document_data.meta.text_map.get(text_id).cloned()
  }

  pub async fn apply_actions(&self, payload: ApplyActionPayloadPB) {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ApplyAction)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn convert_document(
    &self,
    payload: ConvertDocumentPayloadPB,
  ) -> ConvertDocumentResponsePB {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ConvertDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<ConvertDocumentResponsePB>()
  }

  // convert data to json for document event test
  pub async fn convert_data_to_json(
    &self,
    payload: ConvertDataToJsonPayloadPB,
  ) -> ConvertDataToJsonResponsePB {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ConvertDataToJSON)
      .payload(payload)
      .async_send()
      .await
      .parse::<ConvertDataToJsonResponsePB>()
  }

  pub async fn create_text(&self, payload: TextDeltaPayloadPB) {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::CreateText)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn apply_text_delta(&self, payload: TextDeltaPayloadPB) {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ApplyTextDeltaEvent)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn undo(&self, doc_id: String) -> DocumentRedoUndoResponsePB {
    let core = &self.event_test;
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
    let core = &self.event_test;
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
    let core = &self.event_test;
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

  pub async fn apply_delta_for_block(&self, document_id: &str, block_id: &str, delta: String) {
    let block = self.get_block(document_id, block_id).await;
    // Here is unsafe, but it should be fine for testing.
    let text_id = block.unwrap().external_id.unwrap();
    self
      .apply_text_delta(TextDeltaPayloadPB {
        document_id: document_id.to_string(),
        text_id,
        delta: Some(delta),
      })
      .await;
  }

  pub async fn get_document_snapshot_metas(&self, doc_id: &str) -> Vec<DocumentSnapshotMetaPB> {
    let core = &self.event_test;
    let payload = OpenDocumentPayloadPB {
      document_id: doc_id.to_string(),
    };
    EventBuilder::new(core.clone())
      .event(DocumentEvent::GetDocumentSnapshotMeta)
      .payload(payload)
      .async_send()
      .await
      .parse::<RepeatedDocumentSnapshotMetaPB>()
      .items
  }

  pub async fn get_document_snapshot(
    &self,
    snapshot_meta: DocumentSnapshotMetaPB,
  ) -> DocumentSnapshotPB {
    let core = &self.event_test;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::GetDocumentSnapshot)
      .payload(snapshot_meta)
      .async_send()
      .await
      .parse::<DocumentSnapshotPB>()
  }

  /// Insert a new text block at the index of parent's children.
  /// return the new block id.
  pub async fn insert_index(
    &self,
    document_id: &str,
    text: &str,
    index: usize,
    parent_id: Option<&str>,
  ) -> String {
    let text = text.to_string();
    let page_id = self.get_page_id(document_id).await;
    let parent_id = parent_id
      .map(|id| id.to_string())
      .unwrap_or_else(|| page_id);
    let parent_children = self.get_block_children(document_id, &parent_id).await;

    let prev_id = {
      // If index is 0, then the new block will be the first child of parent.
      if index == 0 {
        None
      } else {
        parent_children.and_then(|children| {
          // If index is greater than the length of children, then the new block will be the last child of parent.
          if index >= children.len() {
            children.last().cloned()
          } else {
            children.get(index - 1).cloned()
          }
        })
      }
    };

    let new_block_id = gen_id();
    let data = gen_text_block_data();

    let external_id = gen_id();
    let external_type = "text".to_string();

    self
      .create_text(TextDeltaPayloadPB {
        document_id: document_id.to_string(),
        text_id: external_id.clone(),
        delta: Some(gen_delta_str(&text)),
      })
      .await;

    let new_block = BlockPB {
      id: new_block_id.clone(),
      ty: TEXT_BLOCK_TY.to_string(),
      data,
      parent_id: parent_id.clone(),
      children_id: gen_id(),
      external_id: Some(external_id),
      external_type: Some(external_type),
    };
    let action = BlockActionPB {
      action: BlockActionTypePB::Insert,
      payload: BlockActionPayloadPB {
        block: Some(new_block),
        prev_id,
        parent_id: Some(parent_id),
        text_id: None,
        delta: None,
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: document_id.to_string(),
      actions: vec![action],
    };
    self.apply_actions(payload).await;
    new_block_id
  }

  pub async fn update_data(&self, document_id: &str, block_id: &str, data: HashMap<String, Value>) {
    let block = self.get_block(document_id, block_id).await.unwrap();

    let new_block = {
      let mut new_block = block.clone();
      new_block.data = serde_json::to_string(&data).unwrap();
      new_block
    };
    let action = BlockActionPB {
      action: BlockActionTypePB::Update,
      payload: BlockActionPayloadPB {
        block: Some(new_block),
        prev_id: None,
        parent_id: Some(block.parent_id.clone()),
        text_id: None,
        delta: None,
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: document_id.to_string(),
      actions: vec![action],
    };
    self.apply_actions(payload).await;
  }

  pub async fn delete(&self, document_id: &str, block_id: &str) {
    let block = self.get_block(document_id, block_id).await.unwrap();
    let parent_id = block.parent_id.clone();
    let action = BlockActionPB {
      action: BlockActionTypePB::Delete,
      payload: BlockActionPayloadPB {
        block: Some(block),
        prev_id: None,
        parent_id: Some(parent_id),
        text_id: None,
        delta: None,
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: document_id.to_string(),
      actions: vec![action],
    };
    self.apply_actions(payload).await;
  }
}
