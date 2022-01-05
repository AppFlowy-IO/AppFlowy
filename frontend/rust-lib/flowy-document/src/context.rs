<<<<<<< HEAD
<<<<<<< HEAD
use crate::{
    errors::FlowyError,
    services::{
        controller::DocumentController,
        doc::{DocumentWSReceivers, DocumentWebSocket},
        server::construct_doc_server,
    },
};
use backend_service::configuration::ClientServerConfiguration;

=======
=======
>>>>>>> upstream/main
use crate::errors::FlowyError;
use backend_service::configuration::ClientServerConfiguration;

use crate::{
    controller::DocumentController,
    core::{DocumentWSReceivers, DocumentWebSocket},
    server::construct_doc_server,
};
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
use flowy_database::ConnectionPool;
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
        ws_sender: Arc<dyn DocumentWebSocket>,
        server_config: &ClientServerConfiguration,
    ) -> DocumentContext {
        let server = construct_doc_server(server_config);
        let doc_ctrl = Arc::new(DocumentController::new(server, user.clone(), ws_receivers, ws_sender));
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
