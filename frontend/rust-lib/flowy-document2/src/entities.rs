use std::collections::HashMap;

use flowy_derive::ProtoBuf;

#[derive(Default, ProtoBuf)]
pub struct OpenDocumentPayloadPBV2 {
  #[pb(index = 1)]
  pub document_id: String,
  // Support customize initial data
}

#[derive(Default, ProtoBuf)]
pub struct DocumentDataPB {
  #[pb(index = 1)]
  pub page_id: String,

  #[pb(index = 2)]
  pub blocks: BlocksPB,

  #[pb(index = 3)]
  pub meta: MetaPB,
}

#[derive(Default, ProtoBuf)]
pub struct BlocksPB {
  #[pb(index = 1)]
  pub blocks: HashMap<String, BlockPB>,
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
