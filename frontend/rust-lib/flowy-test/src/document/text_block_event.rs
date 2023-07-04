use crate::document::document_event::DocumentEventTest;
use crate::document::utils::{gen_id, gen_text_block_data};
use flowy_document2::entities::*;
use std::sync::Arc;

const TEXT_BLOCK_TY: &str = "paragraph";

pub struct TextBlockEventTest {
  doc: Arc<DocumentEventTest>,
  doc_id: String,
}

impl TextBlockEventTest {
  pub async fn new() -> Self {
    let doc = DocumentEventTest::new().await;
    let doc_id = doc.create_document().await.id;
    Self {
      doc: Arc::new(doc),
      doc_id,
    }
  }

  pub async fn get(&self, block_id: &str) -> Option<BlockPB> {
    let doc = self.doc.clone();
    let doc_id = self.doc_id.clone();
    doc.get_block(&doc_id, block_id).await
  }

  /// Insert a new text block at the index of parent's children.
  pub async fn insert_index(&self, text: String, index: usize, parent_id: Option<&str>) -> String {
    let doc = self.doc.clone();
    let doc_id = self.doc_id.clone();
    let page_id = self.doc.get_page_id(&doc_id).await;
    let parent_id = parent_id
      .map(|id| id.to_string())
      .unwrap_or_else(|| page_id);
    let parent_children = self.doc.get_block_children(&doc_id, &parent_id).await;

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
    let data = gen_text_block_data(text);

    let new_block = BlockPB {
      id: new_block_id.clone(),
      ty: TEXT_BLOCK_TY.to_string(),
      data,
      parent_id: parent_id.clone(),
      children_id: gen_id(),
    };
    let action = BlockActionPB {
      action: BlockActionTypePB::Insert,
      payload: BlockActionPayloadPB {
        block: new_block,
        prev_id,
        parent_id: Some(parent_id),
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: doc_id,
      actions: vec![action],
    };
    doc.apply_actions(payload).await;
    new_block_id
  }

  pub async fn update(&self, block_id: &str, text: String) {
    let doc = self.doc.clone();
    let doc_id = self.doc_id.clone();
    let block = self.get(block_id).await.unwrap();
    let data = gen_text_block_data(text);
    let new_block = {
      let mut new_block = block.clone();
      new_block.data = data;
      new_block
    };
    let action = BlockActionPB {
      action: BlockActionTypePB::Update,
      payload: BlockActionPayloadPB {
        block: new_block,
        prev_id: None,
        parent_id: Some(block.parent_id.clone()),
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: doc_id,
      actions: vec![action],
    };
    doc.apply_actions(payload).await;
  }

  pub async fn delete(&self, block_id: &str) {
    let doc = self.doc.clone();
    let doc_id = self.doc_id.clone();
    let block = self.get(block_id).await.unwrap();
    let parent_id = block.parent_id.clone();
    let action = BlockActionPB {
      action: BlockActionTypePB::Delete,
      payload: BlockActionPayloadPB {
        block,
        prev_id: None,
        parent_id: Some(parent_id),
      },
    };
    let payload = ApplyActionPayloadPB {
      document_id: doc_id,
      actions: vec![action],
    };
    doc.apply_actions(payload).await;
  }
}
