use super::indexer::FolderIndexManagerImpl;
use crate::entities::{CreateSearchResultPBArgs, SearchFilterPB, SearchResultPB};
use crate::services::manager::{SearchHandler, SearchType};
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;
use std::sync::Arc;

pub struct FolderSearchHandler {
  pub index_manager: Arc<FolderIndexManagerImpl>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Arc<FolderIndexManagerImpl>) -> Self {
    Self { index_manager }
  }
}

#[async_trait]
impl SearchHandler for FolderSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::Folder
  }

  async fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> FlowyResult<SearchResultPB> {
    let mut items = self.index_manager.search(query, filter.clone())?;
    if let Some(filter) = filter {
      if let Some(workspace_id) = filter.workspace_id {
        // Filter results by workspace ID
        items.retain(|result| result.workspace_id == workspace_id);
      }
    }

    Ok(
      CreateSearchResultPBArgs::default()
        .items(items)
        .build()
        .unwrap(),
    )
  }
}
