use std::{
  collections::HashMap,
  ops::{Deref, DerefMut},
  sync::Arc,
  vec,
};

use collab::preclude::Collab;
use collab_document::{
  blocks::{Block, DocumentData, DocumentMeta},
  document::Document as InnerDocument,
};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use nanoid::nanoid;
use parking_lot::Mutex;

use crate::entities::{BlockPB, ChildrenPB, DocumentDataPB2, MetaPB};

#[derive(Clone)]
pub struct Document(Arc<Mutex<InnerDocument>>);

impl Document {
  pub fn new(collab: Collab) -> FlowyResult<Self> {
    let inner = InnerDocument::create(collab)
      .map_err(|_| FlowyError::from(ErrorCode::DocumentDataInvalid))?;
    Ok(Self(Arc::new(Mutex::new(inner))))
  }
}

unsafe impl Sync for Document {}
unsafe impl Send for Document {}

impl Deref for Document {
  type Target = Arc<Mutex<InnerDocument>>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for Document {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

#[derive(Clone)]
pub struct DocumentDataWrapper(pub DocumentData);

impl Deref for DocumentDataWrapper {
  type Target = DocumentData;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for DocumentDataWrapper {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl From<DocumentDataWrapper> for DocumentDataPB2 {
  fn from(data: DocumentDataWrapper) -> Self {
    let blocks = data
      .0
      .blocks
      .into_iter()
      .map(|(id, block)| {
        (
          id,
          BlockPB {
            id: block.id,
            ty: block.ty,
            parent_id: block.parent,
            children_id: block.children,
            data: serde_json::to_string(&block.data).unwrap(),
          },
        )
      })
      .collect::<HashMap<String, BlockPB>>();
    let children_map = data
      .0
      .meta
      .children_map
      .into_iter()
      .map(|(id, children)| {
        (
          id,
          ChildrenPB {
            children: children.into_iter().collect(),
          },
        )
      })
      .collect::<HashMap<String, ChildrenPB>>();
    Self {
      page_id: data.0.page_id,
      blocks,
      meta: MetaPB { children_map },
    }
  }
}

impl Default for DocumentDataWrapper {
  fn default() -> Self {
    let mut blocks: HashMap<String, Block> = HashMap::new();
    let mut meta: HashMap<String, Vec<String>> = HashMap::new();

    // page block
    let page_id = nanoid!(10);
    let children_id = nanoid!(10);
    let root = Block {
      id: page_id.clone(),
      ty: "page".to_string(),
      parent: "".to_string(),
      children: children_id.clone(),
      external_id: None,
      external_type: None,
      data: HashMap::new(),
    };
    blocks.insert(page_id.clone(), root);

    // text block
    let text_block_id = nanoid!(10);
    let text_0_children_id = nanoid!(10);
    let text_block = Block {
      id: text_block_id.clone(),
      ty: "text".to_string(),
      parent: page_id.clone(),
      children: text_0_children_id.clone(),
      external_id: None,
      external_type: None,
      data: HashMap::new(),
    };
    blocks.insert(text_block_id.clone(), text_block);

    // meta
    meta.insert(children_id, vec![text_block_id]);
    meta.insert(text_0_children_id, vec![]);

    Self(DocumentData {
      page_id,
      blocks,
      meta: DocumentMeta { children_map: meta },
    })
  }
}
