use std::{collections::HashMap, sync::Arc};

use crate::{
  document::DocumentDataWrapper,
  entities::{BlocksPB, DocumentDataPB, MetaPB, OpenDocumentPayloadPBV2},
  manager::DocumentManager,
};

use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let context = data.into_inner();
  let document = manager.open_document(&context.document_id)?;
  let document_data = document
    .lock()
    .get_document()
    .map_err(|err| FlowyError::internal().context(err))?;
  data_result_ok(DocumentDataPB::from(DocumentDataWrapper(document_data)))
}
