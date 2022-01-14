use crate::{
    controller::DocumentController,
    errors::FlowyError,
    ws_receivers::DocumentWSReceivers,
    DocumentCloudService,
};
use flowy_database::ConnectionPool;
use flowy_sync::RevisionWebSocket;
use std::sync::Arc;

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct DocumentContext {
    pub controller: Arc<DocumentController>,
    pub user: Arc<dyn DocumentUser>,
}

impl DocumentContext {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        ws_receivers: Arc<DocumentWSReceivers>,
        ws_sender: Arc<dyn RevisionWebSocket>,
        cloud_service: Arc<dyn DocumentCloudService>,
    ) -> DocumentContext {
        let doc_ctrl = Arc::new(DocumentController::new(
            cloud_service,
            user.clone(),
            ws_receivers,
            ws_sender,
        ));
        Self {
            controller: doc_ctrl,
            user,
        }
    }

    pub fn init(&self) -> Result<(), FlowyError> {
        let _ = self.controller.init()?;
        Ok(())
    }
}
