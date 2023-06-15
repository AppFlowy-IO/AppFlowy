use collab_document::blocks::{BlockAction, DocumentData};
use std::collections::HashMap;

use crate::parse::{NotEmptyStr, NotEmptyVec};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(Default, ProtoBuf)]
pub struct OpenDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
}

pub struct OpenDocumentParams {
  pub document_id: String,
}

impl TryInto<OpenDocumentParams> for OpenDocumentPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<OpenDocumentParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    Ok(OpenDocumentParams {
      document_id: document_id.0,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct DocumentRedoUndoPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
}

pub struct DocumentRedoUndoParams {
  pub document_id: String,
}

impl TryInto<DocumentRedoUndoParams> for DocumentRedoUndoPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<DocumentRedoUndoParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    Ok(DocumentRedoUndoParams {
      document_id: document_id.0,
    })
  }
}

#[derive(Default, Debug, ProtoBuf)]
pub struct DocumentRedoUndoResponsePB {
  #[pb(index = 1)]
  pub can_undo: bool,

  #[pb(index = 2)]
  pub can_redo: bool,

  #[pb(index = 3)]
  pub is_success: bool,
}

#[derive(Default, ProtoBuf)]
pub struct CreateDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2, one_of)]
  pub initial_data: Option<DocumentDataPB>,
}

pub struct CreateDocumentParams {
  pub document_id: String,
  pub initial_data: Option<DocumentData>,
}

impl TryInto<CreateDocumentParams> for CreateDocumentPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<CreateDocumentParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    let initial_data = self.initial_data.map(|data| data.into());
    Ok(CreateDocumentParams {
      document_id: document_id.0,
      initial_data,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct CloseDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,
}

pub struct CloseDocumentParams {
  pub document_id: String,
}

impl TryInto<CloseDocumentParams> for CloseDocumentPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<CloseDocumentParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    Ok(CloseDocumentParams {
      document_id: document_id.0,
    })
  }
}

#[derive(Default, ProtoBuf, Debug)]
pub struct ApplyActionPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2)]
  pub actions: Vec<BlockActionPB>,
}

pub struct ApplyActionParams {
  pub document_id: String,
  pub actions: Vec<BlockAction>,
}

impl TryInto<ApplyActionParams> for ApplyActionPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<ApplyActionParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    let actions = NotEmptyVec::parse(self.actions).map_err(|_| ErrorCode::ApplyActionsIsEmpty)?;
    let actions = actions.0.into_iter().map(BlockAction::from).collect();
    Ok(ApplyActionParams {
      document_id: document_id.0,
      actions,
    })
  }
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

#[derive(PartialEq, Eq, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum ExportType {
  #[default]
  Text = 0,
  Markdown = 1,
  Link = 2,
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
#[derive(PartialEq, Eq, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum ConvertType {
  #[default]
  Json = 0,
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

pub struct ConvertDataParams {
  pub convert_type: ConvertType,
  pub data: Vec<u8>,
}

impl TryInto<ConvertDataParams> for ConvertDataPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<ConvertDataParams, Self::Error> {
    let convert_type = self.convert_type;
    let data = self.data;
    Ok(ConvertDataParams { convert_type, data })
  }
}
