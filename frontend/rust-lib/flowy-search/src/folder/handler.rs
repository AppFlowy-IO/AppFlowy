use crate::entities::SearchResultPB;
use crate::services::manager::{SearchHandler, SearchType};
use flowy_error::FlowyResult;
use std::sync::Arc;

use super::indexer::FolderIndexManagerImpl;

pub struct FolderSearchHandler {
  pub index_manager: Arc<FolderIndexManagerImpl>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Arc<FolderIndexManagerImpl>) -> Self {
    Self { index_manager }
  }
}

impl SearchHandler for FolderSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::Folder
  }

  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>> {
    self.index_manager.search(query)
  }

  fn index_count(&self) -> u64 {
    self.index_manager.num_docs()
  }
}
