use crate::{controller::DocumentController, errors::FlowyError};
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
    pub fn init(&self) -> Result<(), FlowyError> {
        let _ = self.controller.init()?;
        Ok(())
    }
}
