use crate::services::indexer::IndexManager;
use crate::services::manager::ISearchHandler;

use super::indexer::FolderIndexManager;

#[derive(Clone)]
pub struct FolderSearchHandler {
  index_manager: Box<FolderIndexManager>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Box<FolderIndexManager>) -> Self {
    Self { index_manager }
  }
}

impl ISearchHandler for FolderSearchHandler {
  fn perform_search(&self, _query: String) {
    tracing::error!("FOLDER SEARCH HANDLER");
  }

  fn get_index_manager(&self) -> Box<(dyn IndexManager)> {
    self.index_manager.clone()
  }
}
