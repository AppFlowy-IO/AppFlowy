/*
 * The following code defines functions that handle creating, opening, and closing documents,
 * as well as performing actions on documents. These functions make use of a DocumentManager,
 * which you can think of as a higher-level interface to interact with documents.
 */

use std::sync::Arc;

use crate::{
  document_data::DocumentDataWrapper,
  entities::{
    ApplyActionPayloadPBV2, BlockActionPB, BlockActionPayloadPB, BlockActionTypePB, BlockEventPB,
    BlockEventPayloadPB, BlockPB, CloseDocumentPayloadPBV2, CreateDocumentPayloadPBV2, DeltaTypePB,
    DocEventPB, DocumentDataPB2, OpenDocumentPayloadPBV2,
  },
  manager::DocumentManager,
};

use collab_document::blocks::{
  json_str_to_hashmap, Block, BlockAction, BlockActionPayload, BlockActionType, BlockEvent,
  BlockEventPayload, DeltaType,
};
use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

// Handler for creating a new document
pub(crate) async fn create_document_handler(
  data: AFPluginData<CreateDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  // Create a new document with a default content, one page block and one text block
  let data = DocumentDataWrapper::default();
  manager.create_document(context.document_id, data)?;
  Ok(())
}

// Handler for opening an existing document
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> DataResult<DocumentDataPB2, FlowyError> {
  let context = data.into_inner();
  let document = manager.open_document(context.document_id)?;
  let document_data = document.lock().get_document()?;
  data_result_ok(DocumentDataPB2::from(DocumentDataWrapper(document_data)))
}

// Handler for closing an existing document
pub(crate) async fn close_document_handler(
  data: AFPluginData<CloseDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  manager.close_document(context.document_id)?;
  Ok(())
}

// Handler for applying an action to a document
pub(crate) async fn apply_action_handler(
  data: AFPluginData<ApplyActionPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  let doc_id = context.document_id;
  let document = manager.open_document(doc_id)?;
  let actions = context.actions.into_iter().map(BlockAction::from).collect();
  document.lock().apply_action(actions);
  Ok(())
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
    }
  }
}

impl From<BlockActionPayloadPB> for BlockActionPayload {
  fn from(pb: BlockActionPayloadPB) -> Self {
    Self {
      block: pb.block.into(),
      parent_id: pb.parent_id,
      prev_id: pb.prev_id,
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
      external_id: None,
      external_type: None,
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
