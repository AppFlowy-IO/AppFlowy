/*
 * The following code defines functions that handle creating, opening, and closing documents,
 * as well as performing actions on documents. These functions make use of a DocumentManager,
 * which you can think of as a higher-level interface to interact with documents.
 */

use std::sync::{Arc, Weak};

use collab_document::blocks::{
  json_str_to_hashmap, Block, BlockAction, BlockActionPayload, BlockActionType, BlockEvent,
  BlockEventPayload, DeltaType,
};

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::entities::*;
use crate::{manager::DocumentManager, parser::json::parser::JsonToDocumentParser};

fn upgrade_document(
  document_manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<Arc<DocumentManager>> {
  let manager = document_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The document manager is already dropped"))?;
  Ok(manager)
}

// Handler for creating a new document
pub(crate) async fn create_document_handler(
  data: AFPluginData<CreateDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: CreateDocumentParams = data.into_inner().try_into()?;
  let uid = manager.user.user_id()?;
  manager
    .create_document(uid, &params.document_id, params.initial_data)
    .await?;
  Ok(())
}

// Handler for opening an existing document
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document_data = document.lock().get_document_data()?;
  data_result_ok(DocumentDataPB::from(document_data))
}

pub(crate) async fn close_document_handler(
  data: AFPluginData<CloseDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: CloseDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  manager.close_document(&doc_id)?;
  Ok(())
}

// Get the content of the existing document,
//  if the document does not exist, return an error.
pub(crate) async fn get_document_data_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document_data = manager.get_document_data(&doc_id).await?;
  data_result_ok(DocumentDataPB::from(document_data))
}

// Handler for applying an action to a document
pub(crate) async fn apply_action_handler(
  data: AFPluginData<ApplyActionPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: ApplyActionParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let actions = params.actions;
  document.lock().apply_action(actions);
  Ok(())
}

/// Handler for creating a text
pub(crate) async fn create_text_handler(
  data: AFPluginData<TextDeltaPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: TextDeltaParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  document.create_text(&params.text_id, params.delta);
  Ok(())
}

/// Handler for applying delta to a text
pub(crate) async fn apply_text_delta_handler(
  data: AFPluginData<TextDeltaPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: TextDeltaParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let text_id = params.text_id;
  let delta = params.delta;
  let document = document.lock();
  document.apply_text_delta(&text_id, delta);
  Ok(())
}

pub(crate) async fn convert_data_to_document(
  data: AFPluginData<ConvertDataPayloadPB>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let payload = data.into_inner();
  let document = convert_data_to_document_internal(payload)?;
  data_result_ok(document)
}

pub fn convert_data_to_document_internal(
  payload: ConvertDataPayloadPB,
) -> Result<DocumentDataPB, FlowyError> {
  let params: ConvertDataParams = payload.try_into()?;
  let convert_type = params.convert_type;
  let data = params.data;
  match convert_type {
    ConvertType::Json => {
      let json_str = String::from_utf8(data).map_err(|_| FlowyError::invalid_data())?;
      let document = JsonToDocumentParser::json_str_to_document(&json_str)?;
      Ok(document)
    },
  }
}

pub(crate) async fn redo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let redo = document.redo();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: redo,
  })
}

pub(crate) async fn undo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let undo = document.undo();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: undo,
  })
}

pub(crate) async fn can_undo_redo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  drop(document);
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: true,
  })
}

pub(crate) async fn get_snapshot_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<RepeatedDocumentSnapshotPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let snapshots = manager.get_document_snapshots(&doc_id, 10).await?;
  data_result_ok(RepeatedDocumentSnapshotPB { items: snapshots })
}

impl From<BlockActionPB> for BlockAction {
  fn from(pb: BlockActionPB) -> Self {
    Self {
      action: pb.action.into(),
      payload: pb.payload.into(),
    }
  }
}

impl From<BlockActionTypePB> for BlockActionType {
  fn from(pb: BlockActionTypePB) -> Self {
    match pb {
      BlockActionTypePB::Insert => Self::Insert,
      BlockActionTypePB::Update => Self::Update,
      BlockActionTypePB::Delete => Self::Delete,
      BlockActionTypePB::Move => Self::Move,
      BlockActionTypePB::InsertText => Self::InsertText,
      BlockActionTypePB::ApplyTextDelta => Self::ApplyTextDelta,
    }
  }
}

impl From<BlockActionPayloadPB> for BlockActionPayload {
  fn from(pb: BlockActionPayloadPB) -> Self {
    Self {
      block: Some(pb.block.into()),
      parent_id: pb.parent_id,
      prev_id: pb.prev_id,
      text_id: pb.text_id,
      delta: pb.delta,
    }
  }
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

impl From<BlockEvent> for BlockEventPB {
  fn from(payload: BlockEvent) -> Self {
    // Convert each individual `BlockEvent` to a protobuf `BlockEventPB`, and collect the results into a `Vec`
    Self {
      event: payload.iter().map(|e| e.to_owned().into()).collect(),
    }
  }
}

impl From<BlockEventPayload> for BlockEventPayloadPB {
  fn from(payload: BlockEventPayload) -> Self {
    Self {
      command: payload.command.into(),
      path: payload.path,
      id: payload.id,
      value: payload.value,
    }
  }
}

impl From<DeltaType> for DeltaTypePB {
  fn from(action: DeltaType) -> Self {
    match action {
      DeltaType::Inserted => Self::Inserted,
      DeltaType::Updated => Self::Updated,
      DeltaType::Removed => Self::Removed,
    }
  }
}

impl From<(&Vec<BlockEvent>, bool)> for DocEventPB {
  fn from((events, is_remote): (&Vec<BlockEvent>, bool)) -> Self {
    // Convert each individual `BlockEvent` to a protobuf `BlockEventPB`, and collect the results into a `Vec`
    Self {
      events: events.iter().map(|e| e.to_owned().into()).collect(),
      is_remote,
    }
  }
}
