use crate::{
    errors::DocError,
    services::{doc_controller::DocController, file_manager::FileManager, server::construct_doc_server},
};

use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DocumentUser: Send + Sync {
    fn user_doc_dir(&self) -> Result<String, DocError>;
    fn user_id(&self) -> Result<String, DocError>;
    fn token(&self) -> Result<String, DocError>;
}

pub enum DocumentType {
    Doc,
}

pub struct Document {
    user: Arc<dyn DocumentUser>,
    file_manager: RwLock<FileManager>,
    pub doc: Arc<DocController>,
}

impl Document {
    pub fn new(user: Arc<dyn DocumentUser>) -> Document {
        let server = construct_doc_server();
        let doc_controller = Arc::new(DocController::new(server.clone(), user.clone()));
        let file_manager = RwLock::new(FileManager::new(user.clone()));
        Self {
            user,
            file_manager,
            doc: doc_controller,
        }
    }
}
