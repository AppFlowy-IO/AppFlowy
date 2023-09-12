use collab_document::blocks::{Block, DocumentData, DocumentMeta};

use crate::entities::{BlockPB, ChildrenPB, DocumentDataPB, MetaPB};

impl From<DocumentData> for DocumentDataPB {
  fn from(data: DocumentData) -> Self {
    let blocks = data
      .blocks
      .into_iter()
      .map(|(id, block)| (id, block.into()))
      .collect();

    let children_map = data
      .meta
      .children_map
      .into_iter()
      .map(|(id, children)| (id, children.into()))
      .collect();

    let text_map = data.meta.text_map.unwrap_or_default();

    let page_id = data.page_id;

    Self {
      page_id,
      blocks,
      meta: MetaPB {
        children_map,
        text_map,
      },
    }
  }
}

impl From<DocumentDataPB> for DocumentData {
  fn from(data: DocumentDataPB) -> Self {
    let blocks = data
      .blocks
      .into_iter()
      .map(|(id, block)| (id, block.into()))
      .collect();

    let children_map = data
      .meta
      .children_map
      .into_iter()
      .map(|(id, children)| (id, children.children))
      .collect();

    let text_map = data.meta.text_map;
    let page_id = data.page_id;

    DocumentData {
      page_id,
      blocks,
      meta: DocumentMeta {
        children_map,
        text_map: Some(text_map),
      },
    }
  }
}

impl From<Block> for BlockPB {
  fn from(block: Block) -> Self {
    Self {
      id: block.id,
      ty: block.ty,
      data: serde_json::to_string(&block.data).unwrap_or_default(),
      parent_id: block.parent,
      children_id: block.children,
      external_id: block.external_id,
      external_type: block.external_type,
    }
  }
}

impl From<Vec<String>> for ChildrenPB {
  fn from(children: Vec<String>) -> Self {
    Self { children }
  }
}
