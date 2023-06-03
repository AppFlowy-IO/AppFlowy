use std::collections::HashMap;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Default, ProtoBuf)]
pub struct OpenDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct CreateDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2, one_of)]
  pub initial_data: Option<DocumentDataPB>,
}

#[derive(Default, ProtoBuf)]
pub struct CloseDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct ApplyActionPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2)]
  pub actions: Vec<BlockActionPB>,
}

#[derive(Default, ProtoBuf)]
pub struct GetDocumentDataPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
  // Support customize initial data
}

#[derive(Default, Debug, ProtoBuf)]
pub struct DocumentDataPB {
  #[pb(index = 1)]
  pub page_id: String,

  #[pb(index = 2)]
  pub blocks: HashMap<String, BlockPB>,

  #[pb(index = 3)]
  pub meta: MetaPB,
}

#[derive(Default, ProtoBuf, Debug)]
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

#[derive(Default, ProtoBuf, Debug)]
pub struct MetaPB {
  #[pb(index = 1)]
  pub children_map: HashMap<String, ChildrenPB>,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct ChildrenPB {
  #[pb(index = 1)]
  pub children: Vec<String>,
}
// Actions
#[derive(Default, ProtoBuf, Debug)]
pub struct BlockActionPB {
  #[pb(index = 1)]
  pub action: BlockActionTypePB,

  #[pb(index = 2)]
  pub payload: BlockActionPayloadPB,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct BlockActionPayloadPB {
  #[pb(index = 1)]
  pub block: BlockPB,

  #[pb(index = 2, one_of)]
  pub prev_id: Option<String>,

  #[pb(index = 3, one_of)]
  pub parent_id: Option<String>,
}

#[derive(ProtoBuf_Enum, Debug)]
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

#[derive(ProtoBuf_Enum)]
pub enum DeltaTypePB {
  Inserted = 0,
  Updated = 1,
  Removed = 2,
}
impl Default for DeltaTypePB {
  fn default() -> Self {
    Self::Inserted
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
  pub event: Vec<BlockEventPayloadPB>,
}

#[derive(Default, ProtoBuf)]
pub struct BlockEventPayloadPB {
  #[pb(index = 1)]
  pub command: DeltaTypePB,

  #[pb(index = 2)]
  pub path: Vec<String>,

  #[pb(index = 3)]
  pub id: String,

  #[pb(index = 4)]
  pub value: String,
}

#[derive(PartialEq, Eq, Debug, ProtoBuf_Enum, Clone)]
pub enum ExportType {
  Text = 0,
  Markdown = 1,
  Link = 2,
}

impl Default for ExportType {
  fn default() -> Self {
    ExportType::Text
  }
}

impl From<i32> for ExportType {
  fn from(val: i32) -> Self {
    match val {
      0 => ExportType::Text,
      1 => ExportType::Markdown,
      2 => ExportType::Link,
      _ => {
        tracing::error!("Invalid export type: {}", val);
        ExportType::Text
      },
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct EditPayloadPB {
  #[pb(index = 1)]
  pub doc_id: String,

  // Encode in JSON format
  #[pb(index = 2)]
  pub operations: String,
}

#[derive(Default, ProtoBuf)]
pub struct ExportDataPB {
  #[pb(index = 1)]
  pub data: String,

  #[pb(index = 2)]
  pub export_type: ExportType,
}
#[derive(PartialEq, Eq, Debug, ProtoBuf_Enum, Clone)]
pub enum ConvertType {
  Json = 0,
}

impl Default for ConvertType {
  fn default() -> Self {
    ConvertType::Json
  }
}

impl From<i32> for ConvertType {
  fn from(val: i32) -> Self {
    match val {
      0 => ConvertType::Json,
      _ => {
        tracing::error!("Invalid export type: {}", val);
        ConvertType::Json
      },
    }
  }
}

/// for the json type
/// the data is the json string
#[derive(Default, ProtoBuf, Debug)]
pub struct ConvertDataPayloadPB {
  #[pb(index = 1)]
  pub convert_type: ConvertType,

  #[pb(index = 2)]
  pub data: Vec<u8>,
}
