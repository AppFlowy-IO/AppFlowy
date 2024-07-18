use std::collections::HashMap;

use collab::core::collab_state::SyncState;
use collab_document::{
  blocks::{json_str_to_hashmap, Block, BlockAction, DocumentData},
  document_awareness::{
    DocumentAwarenessPosition, DocumentAwarenessSelection, DocumentAwarenessState,
    DocumentAwarenessUser,
  },
};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use lib_infra::validator_fn::{required_not_empty_str, required_valid_path};
use validator::Validate;

use crate::parse::{NotEmptyStr, NotEmptyVec};

#[derive(Default, ProtoBuf)]
pub struct EncodedCollabPB {
  #[pb(index = 1)]
  pub state_vector: Vec<u8>,
  #[pb(index = 2)]
  pub doc_state: Vec<u8>,
}

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

#[derive(Default, ProtoBuf, Validate)]
pub struct UploadFileParamsPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub document_id: String,

  #[pb(index = 3)]
  #[validate(custom = "required_valid_path")]
  pub local_file_path: String,
}

#[derive(Default, ProtoBuf, Validate)]
pub struct UploadedFilePB {
  #[pb(index = 1)]
  #[validate(url)]
  pub url: String,

  #[pb(index = 2)]
  #[validate(custom = "required_valid_path")]
  pub local_file_path: String,
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

#[derive(Default, ProtoBuf, Debug, Clone)]
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

  #[pb(index = 6, one_of)]
  pub external_id: Option<String>,

  #[pb(index = 7, one_of)]
  pub external_type: Option<String>,
}

impl From<BlockPB> for Block {
  fn from(pb: BlockPB) -> Self {
    // Use `json_str_to_hashmap()` from the `collab_document` crate to convert the JSON data to a hashmap
    let data = json_str_to_hashmap(&pb.data).unwrap_or_default();

    // Convert the protobuf `BlockPB` to our internal `Block` struct
    Self {
      id: pb.id,
      ty: pb.ty,
      children: pb.children_id,
      parent: pb.parent_id,
      data,
      external_id: pb.external_id,
      external_type: pb.external_type,
    }
  }
}

#[derive(Default, ProtoBuf, Debug)]
pub struct MetaPB {
  #[pb(index = 1)]
  pub children_map: HashMap<String, ChildrenPB>,
  #[pb(index = 2)]
  pub text_map: HashMap<String, String>,
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
  // When action = Insert, Update, Delete or Move, block needs to be passed.
  #[pb(index = 1, one_of)]
  pub block: Option<BlockPB>,

  // When action = Insert or Move, prev_id needs to be passed.
  #[pb(index = 2, one_of)]
  pub prev_id: Option<String>,

  // When action = Insert or Move, parent_id needs to be passed.
  #[pb(index = 3, one_of)]
  pub parent_id: Option<String>,

  // When action = InsertText or ApplyTextDelta, text_id needs to be passed.
  #[pb(index = 4, one_of)]
  pub text_id: Option<String>,

  // When action = InsertText or ApplyTextDelta, delta needs to be passed.
  // The format of delta is a JSON string, similar to the serialization result of [{ "insert": "Hello World" }].
  #[pb(index = 5, one_of)]
  pub delta: Option<String>,
}

#[derive(ProtoBuf_Enum, Debug)]
pub enum BlockActionTypePB {
  Insert = 0,
  Update = 1,
  Delete = 2,
  Move = 3,
  InsertText = 4,
  ApplyTextDelta = 5,
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

  #[pb(index = 3, one_of)]
  pub new_snapshot: Option<DocumentDataPB>,
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
  HTML = 3,
}

impl From<i32> for ExportType {
  fn from(val: i32) -> Self {
    match val {
      0 => ExportType::Text,
      1 => ExportType::Markdown,
      2 => ExportType::Link,
      3 => ExportType::HTML,
      _ => {
        tracing::error!("🔴Invalid export type: {}", val);
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
        tracing::error!("🔴Invalid export type: {}", val);
        ConvertType::Json
      },
    }
  }
}

/// for convert data to document
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

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedDocumentSnapshotMetaPB {
  #[pb(index = 1)]
  pub items: Vec<DocumentSnapshotMetaPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DocumentSnapshotMetaPB {
  #[pb(index = 1)]
  pub snapshot_id: String,

  #[pb(index = 2)]
  pub object_id: String,

  #[pb(index = 3)]
  pub created_at: i64,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DocumentSnapshotPB {
  #[pb(index = 1)]
  pub object_id: String,

  #[pb(index = 2)]
  pub encoded_v1: Vec<u8>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DocumentSnapshotStatePB {
  #[pb(index = 1)]
  pub new_snapshot_id: i64,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DocumentSyncStatePB {
  #[pb(index = 1)]
  pub value: DocumentSyncState,
}

#[derive(Debug, Default, ProtoBuf_Enum, PartialEq, Eq, Clone, Copy)]
pub enum DocumentSyncState {
  #[default]
  InitSyncBegin = 0,
  InitSyncEnd = 1,
  Syncing = 2,
  SyncFinished = 3,
}

impl From<SyncState> for DocumentSyncStatePB {
  fn from(value: SyncState) -> Self {
    let value = match value {
      SyncState::InitSyncBegin => DocumentSyncState::InitSyncBegin,
      SyncState::InitSyncEnd => DocumentSyncState::InitSyncEnd,
      SyncState::Syncing => DocumentSyncState::Syncing,
      SyncState::SyncFinished => DocumentSyncState::SyncFinished,
    };
    Self { value }
  }
}

#[derive(Default, ProtoBuf, Debug)]
pub struct TextDeltaPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2)]
  pub text_id: String,

  #[pb(index = 3, one_of)]
  pub delta: Option<String>,
}

pub struct TextDeltaParams {
  pub document_id: String,
  pub text_id: String,
  pub delta: String,
}

impl TryInto<TextDeltaParams> for TextDeltaPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<TextDeltaParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    let text_id = NotEmptyStr::parse(self.text_id).map_err(|_| ErrorCode::TextIdIsEmpty)?;
    let delta = self.delta.map_or_else(|| "".to_string(), |delta| delta);
    Ok(TextDeltaParams {
      document_id: document_id.0,
      text_id: text_id.0,
      delta,
    })
  }
}

pub struct DocumentSnapshotMeta {
  pub snapshot_id: String,
  pub object_id: String,
  pub created_at: i64,
}

pub struct DocumentSnapshotData {
  pub object_id: String,
  pub encoded_v1: Vec<u8>,
}

#[derive(ProtoBuf, Debug, Default)]
pub struct DocumentAwarenessStatesPB {
  #[pb(index = 1)]
  pub value: HashMap<String, DocumentAwarenessStatePB>,
}

impl From<HashMap<u64, DocumentAwarenessState>> for DocumentAwarenessStatesPB {
  fn from(value: HashMap<u64, DocumentAwarenessState>) -> Self {
    let value = value
      .into_iter()
      .map(|(k, v)| (k.to_string(), v.into()))
      .collect();
    Self { value }
  }
}

#[derive(ProtoBuf, Debug, Default)]
pub struct UpdateDocumentAwarenessStatePB {
  #[pb(index = 1)]
  pub document_id: String,
  #[pb(index = 2, one_of)]
  pub selection: Option<DocumentAwarenessSelectionPB>,
  #[pb(index = 3, one_of)]
  pub metadata: Option<String>,
}

#[derive(ProtoBuf, Debug, Default)]
pub struct DocumentAwarenessStatePB {
  #[pb(index = 1)]
  pub version: i64,
  #[pb(index = 2)]
  pub user: DocumentAwarenessUserPB,
  #[pb(index = 3, one_of)]
  pub selection: Option<DocumentAwarenessSelectionPB>,
  #[pb(index = 4, one_of)]
  pub metadata: Option<String>,
  #[pb(index = 5)]
  pub timestamp: i64,
}

impl From<DocumentAwarenessState> for DocumentAwarenessStatePB {
  fn from(value: DocumentAwarenessState) -> Self {
    DocumentAwarenessStatePB {
      version: value.version,
      user: value.user.into(),
      selection: value.selection.map(|s| s.into()),
      metadata: value.metadata,
      timestamp: value.timestamp,
    }
  }
}

#[derive(ProtoBuf, Debug, Default)]
pub struct DocumentAwarenessUserPB {
  #[pb(index = 1)]
  pub uid: i64,
  #[pb(index = 2)]
  pub device_id: String,
}

impl From<DocumentAwarenessUser> for DocumentAwarenessUserPB {
  fn from(value: DocumentAwarenessUser) -> Self {
    DocumentAwarenessUserPB {
      uid: value.uid,
      device_id: value.device_id.to_string(),
    }
  }
}

#[derive(ProtoBuf, Debug, Default)]
pub struct DocumentAwarenessSelectionPB {
  #[pb(index = 1)]
  pub start: DocumentAwarenessPositionPB,
  #[pb(index = 2)]
  pub end: DocumentAwarenessPositionPB,
}

#[derive(ProtoBuf, Debug, Default)]
pub struct DocumentAwarenessPositionPB {
  #[pb(index = 1)]
  pub path: Vec<u64>,
  #[pb(index = 2)]
  pub offset: u64,
}

impl From<DocumentAwarenessSelectionPB> for DocumentAwarenessSelection {
  fn from(value: DocumentAwarenessSelectionPB) -> Self {
    DocumentAwarenessSelection {
      start: value.start.into(),
      end: value.end.into(),
    }
  }
}

impl From<DocumentAwarenessSelection> for DocumentAwarenessSelectionPB {
  fn from(value: DocumentAwarenessSelection) -> Self {
    DocumentAwarenessSelectionPB {
      start: value.start.into(),
      end: value.end.into(),
    }
  }
}

impl From<DocumentAwarenessPositionPB> for DocumentAwarenessPosition {
  fn from(value: DocumentAwarenessPositionPB) -> Self {
    DocumentAwarenessPosition {
      path: value.path,
      offset: value.offset,
    }
  }
}

impl From<DocumentAwarenessPosition> for DocumentAwarenessPositionPB {
  fn from(value: DocumentAwarenessPosition) -> Self {
    DocumentAwarenessPositionPB {
      path: value.path,
      offset: value.offset,
    }
  }
}
