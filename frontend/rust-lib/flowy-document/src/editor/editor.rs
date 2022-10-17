use crate::{DocumentEditor, DocumentUser};
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{RevisionCloudService, RevisionManager};
use flowy_sync::entities::ws_data::ServerRevisionWSData;
use lib_infra::future::FutureResult;
use lib_ws::WSConnectState;
use std::any::Any;
use std::sync::Arc;

pub struct AppFlowyDocumentEditor {
    doc_id: String,
}

impl AppFlowyDocumentEditor {
    pub async fn new(
        doc_id: &str,
        user: Arc<dyn DocumentUser>,
        mut rev_manager: RevisionManager,
        cloud_service: Arc<dyn RevisionCloudService>,
    ) -> FlowyResult<Arc<Self>> {
        todo!()
    }
}

impl DocumentEditor for Arc<AppFlowyDocumentEditor> {
    fn get_operations_str(&self) -> FutureResult<String, FlowyError> {
        todo!()
    }

    fn compose_local_operations(&self, data: Bytes) -> FutureResult<(), FlowyError> {
        todo!()
    }

    fn close(&self) {
        todo!()
    }

    fn receive_ws_data(&self, data: ServerRevisionWSData) -> FutureResult<(), FlowyError> {
        todo!()
    }

    fn receive_ws_state(&self, state: &WSConnectState) {
        todo!()
    }

    fn as_any(&self) -> &dyn Any {
        self
    }
}
