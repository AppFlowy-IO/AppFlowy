use crate::{
  entities::{SearchFilterPB, SearchResultPB},
  services::manager::{SearchHandler, SearchType},
};
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

  fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> FlowyResult<Vec<SearchResultPB>> {
    let mut results = self.index_manager.search(query, filter.clone())?;
    if let Some(filter) = filter {
      if let Some(workspace_id) = filter.workspace_id {
        // Filter results by workspace ID
        results = results
          .into_iter()
          .filter(|result| result.workspace_id == workspace_id)
          .collect();
      }
    }

    Ok(results)
  }

  fn index_count(&self) -> u64 {
    self.index_manager.num_docs()
  }
}
