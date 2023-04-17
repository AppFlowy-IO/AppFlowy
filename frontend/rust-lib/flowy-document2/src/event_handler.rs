use std::{sync::Arc};

use crate::{
  document::DocumentDataWrapper,
  entities::{
    ApplyActionPayloadPBV2, BlockActionPB, BlockActionPayloadPB, BlockActionTypePB,
    BlockPB, CloseDocumentPayloadPBV2, DocumentDataPB2, OpenDocumentPayloadPBV2, CreateDocumentPayloadPBV2,
    BlockEventPB
  },
  manager::DocumentManager,
};

use collab_document::blocks::{
  json_str_to_hashmap, Block, BlockAction, BlockActionPayload, BlockActionType, BlockEvent
};
use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> DataResult<DocumentDataPB2, FlowyError> {
  let context = data.into_inner();
  let document = manager.open_document(context.document_id)?;
  let document_data = document
    .lock()
    .get_document()
    .map_err(|err| FlowyError::internal().context(err))?;
  data_result_ok(DocumentDataPB2::from(DocumentDataWrapper(document_data)))
}

pub(crate) async fn create_document_handler(
  data: AFPluginData<CreateDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  let data = DocumentDataWrapper::default();
  manager.create_document(context.document_id, data)?;
  Ok(())
}

pub(crate) async fn close_document_handler(
  data: AFPluginData<CloseDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  manager.close_document(context.document_id)?;
  Ok(())
}

pub(crate) async fn apply_action_handler(
  data: AFPluginData<ApplyActionPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  let doc_id = context.document_id;
  let actions = context
    .actions
    .into_iter()
    .map(|action| action.into())
    .collect();
  let document = manager.open_document(doc_id)?;
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
    let data = json_str_to_hashmap(&pb.data).unwrap_or_default();
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
  fn from(block_event: BlockEvent) -> Self {
    let delta = serde_json::to_value(&block_event.delta).unwrap();
    Self {
      path: block_event.path.into(),
      delta: delta.to_string(),
    }
  }
}
