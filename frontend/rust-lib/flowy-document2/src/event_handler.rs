use std::sync::Arc;

use crate::{
  document::DocumentDataWrapper,
  entities::{
    ApplyActionPayloadPBV2, BlockActionPB, BlockActionPayloadPB, BlockActionTypePB,
    BlockEventPayloadPB, BlockPB, CloseDocumentPayloadPBV2, CreateDocumentPayloadPBV2, DeltaTypePB,
    DocumentDataPB2, OpenDocumentPayloadPBV2,
  },
  manager::DocumentManager,
};

use collab_document::blocks::{
  json_str_to_hashmap, Block, BlockAction, BlockActionPayload, BlockActionType, BlockEventPayload,
  DeltaType,
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
  let pb = DocumentDataPB2::from(DocumentDataWrapper(document_data));
  data_result_ok(pb)
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

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn apply_action_handler(
  data: AFPluginData<ApplyActionPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> FlowyResult<()> {
  let context = data.into_inner();
  tracing::trace!("{:?}", context);
  let doc_id = context.document_id;
  let actions = context
    .actions
    .into_iter()
    .map(|action| action.into())
    .collect();
  let document = manager.open_document(doc_id)?;
  document.lock().apply_action(actions);
  drop(document);
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
