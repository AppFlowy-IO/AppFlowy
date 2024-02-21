use flowy_error::FlowyResult;

use crate::entities::SearchResultPB;
use crate::services::indexer::IndexManager;
use crate::services::manager::ISearchHandler;

use super::indexer::FolderIndexManager;

pub struct FolderSearchHandler {
  index_manager: Box<FolderIndexManager>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Box<FolderIndexManager>) -> Self {
    Self { index_manager }
  }
}

impl ISearchHandler for FolderSearchHandler {
  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>> {
    let index_manager = self.index_manager.clone();
    let typed = index_manager
      .as_any()
      .downcast_ref::<FolderIndexManager>()
      .unwrap();
    typed.search(query)
  }
}
