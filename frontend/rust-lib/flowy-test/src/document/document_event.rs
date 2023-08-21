use flowy_document2::entities::*;
use flowy_document2::event_map::DocumentEvent;
use flowy_folder2::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder2::event_map::FolderEvent;
use serde_json::Value;
use std::collections::HashMap;

use crate::document::utils::{gen_delta_str, gen_id, gen_text_block_data};
use crate::event_builder::EventBuilder;
use crate::FlowyCoreTest;

const TEXT_BLOCK_TY: &str = "paragraph";

pub struct DocumentEventTest {
  inner: FlowyCoreTest,
}

pub struct OpenDocumentData {
  pub id: String,
  pub data: DocumentDataPB,
}

impl DocumentEventTest {
  pub async fn new() -> Self {
    let sdk = FlowyCoreTest::new_with_guest_user().await;
    Self { inner: sdk }
  }

  pub fn new_with_core(core: FlowyCoreTest) -> Self {
    Self { inner: core }
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
      index: None,
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

  pub async fn get_block(&self, doc_id: &str, block_id: &str) -> Option<BlockPB> {
    let document = self.open_document(doc_id.to_string()).await;
    document.data.blocks.get(block_id).cloned()
  }

  pub async fn get_page_id(&self, doc_id: &str) -> String {
    let data = self.get_document_data(doc_id).await;
    data.page_id
  }

  pub async fn get_document_data(&self, doc_id: &str) -> DocumentDataPB {
    let document = self.open_document(doc_id.to_string()).await;
    document.data
  }

  pub async fn get_block_children(&self, doc_id: &str, block_id: &str) -> Option<Vec<String>> {
    let block = self.get_block(doc_id, block_id).await;
    block.as_ref()?;
    let document_data = self.get_document_data(doc_id).await;
    let children_map = document_data.meta.children_map;
    let children_id = block.unwrap().children_id;
    children_map.get(&children_id).map(|c| c.children.clone())
  }

  pub async fn get_block_text_delta(&self, doc_id: &str, text_id: &str) -> Option<String> {
    let document_data = self.get_document_data(doc_id).await;
    document_data.meta.text_map.get(text_id).cloned()
  }

  pub async fn apply_actions(&self, payload: ApplyActionPayloadPB) {
    let core = &self.inner;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ApplyAction)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn create_text(&self, payload: TextDeltaPayloadPB) {
    let core = &self.inner;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::CreateText)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn apply_text_delta(&self, payload: TextDeltaPayloadPB) {
    let core = &self.inner;
    EventBuilder::new(core.clone())
      .event(DocumentEvent::ApplyTextDeltaEvent)
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

  pub async fn apply_delta_for_block(&self, document_id: &str, block_id: &str, delta: String) {
    let block = self.get_block(document_id, block_id).await;
    let text_id = block.unwrap().external_id.unwrap();
    self
      .apply_text_delta(TextDeltaPayloadPB {
        document_id: document_id.to_string(),
        text_id,
        delta: Some(delta),
      })
      .await;
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
        block: new_block,
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
        block: new_block,
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
        block,
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
