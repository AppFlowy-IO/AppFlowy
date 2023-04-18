use std::collections::HashMap;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Default, ProtoBuf)]
pub struct OpenDocumentPayloadPBV2 {
  #[pb(index = 1)]
  pub document_id: String,
  // Support customize initial data
}

#[derive(Default, ProtoBuf)]
pub struct CreateDocumentPayloadPBV2 {
  #[pb(index = 1)]
  pub document_id: String,
  // Support customize initial data
}

#[derive(Default, ProtoBuf)]
pub struct CloseDocumentPayloadPBV2 {
  #[pb(index = 1)]
  pub document_id: String,
  // Support customize initial data
}

#[derive(Default, ProtoBuf)]
pub struct ApplyActionPayloadPBV2 {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2)]
  pub actions: Vec<BlockActionPB>,
}

#[derive(Default, ProtoBuf)]
pub struct DocumentDataPB2 {
  #[pb(index = 1)]
  pub page_id: String,

  #[pb(index = 2)]
  pub blocks: HashMap<String, BlockPB>,

  #[pb(index = 3)]
  pub meta: MetaPB,
}

#[derive(Default, ProtoBuf)]
pub struct BlockPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub ty: String,

  #[pb(index = 3)]
  pub data: String,

  #[pb(index = 4)]
  pub parent_id: String,

  #[pb(index = 5)]
  pub children_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct MetaPB {
  #[pb(index = 1)]
  pub children_map: HashMap<String, ChildrenPB>,
}

#[derive(Default, ProtoBuf)]
pub struct ChildrenPB {
  #[pb(index = 1)]
  pub children: Vec<String>,
}

// Actions
#[derive(Default, ProtoBuf)]
pub struct BlockActionPB {
  #[pb(index = 1)]
  pub action: BlockActionTypePB,

  #[pb(index = 2)]
  pub payload: BlockActionPayloadPB,
}

#[derive(Default, ProtoBuf)]
pub struct BlockActionPayloadPB {
  #[pb(index = 1)]
  pub block: BlockPB,

  #[pb(index = 2, one_of)]
  pub prev_id: Option<String>,

  #[pb(index = 3, one_of)]
  pub parent_id: Option<String>,
}

#[derive(ProtoBuf_Enum)]
pub enum BlockActionTypePB {
  Insert = 0,
  Update = 1,
  Delete = 2,
  Move = 3,
}

impl Default for BlockActionTypePB {
  fn default() -> Self {
    Self::Insert
  }
}

#[derive(Default, ProtoBuf)]
pub struct DocEventPB {
  #[pb(index = 1)]
  pub events: Vec<BlockEventPB>,

  #[pb(index = 2)]
  pub is_remote: bool,
}

#[derive(Default, ProtoBuf)]
pub struct BlockEventPB {
  #[pb(index = 1)]
  pub path: Vec<String>,

  #[pb(index = 2)]
  pub delta: String,
}
