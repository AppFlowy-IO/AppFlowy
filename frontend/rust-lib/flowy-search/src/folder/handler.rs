use std::sync::Arc;

use flowy_error::FlowyResult;

use crate::entities::SearchResultPB;
use crate::services::manager::SearchHandler;

use super::indexer::FolderIndexManagerImpl;

pub struct FolderSearchHandler {
  index_manager: Arc<FolderIndexManagerImpl>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Arc<FolderIndexManagerImpl>) -> Self {
    Self { index_manager }
  }
}

impl SearchHandler for FolderSearchHandler {
  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>> {
    self.index_manager.search(query)
  }
}
