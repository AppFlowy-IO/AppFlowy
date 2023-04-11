use std::{collections::HashMap, sync::Arc};

use crate::{
  entities::{BlocksPB, DocumentPB, MetaPB, OpenDocumentPayloadPBV2},
  manager::DocumentManager,
};

use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPBV2>,
  manager: AFPluginState<Arc<DocumentManager>>,
) -> DataResult<DocumentPB, FlowyError> {
  let context = data.into_inner();
  let _ = manager.open_document(&context.document_id)?;
  // implement into for DocumentPB
  data_result_ok(DocumentPB {
    page_id: context.document_id,
    blocks: BlocksPB {
      blocks: HashMap::new(), // FIXME: implement get all blocks on collab-document.
    },
    meta: MetaPB {
      children_map: HashMap::new(), // FIXME: implement get all blocks on collab-document.
    },
  })
}
