use std::sync::Arc;

use flowy_error::FlowyResult;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;

use crate::{
  entities::{IndexTypePB, SearchFilterPB, SearchResultPB},
  services::manager::{SearchHandler, SearchType},
};

pub struct DocumentSearchHandler {
  pub cloud_service: Arc<dyn SearchCloudService>,
}

impl DocumentSearchHandler {
  pub fn new(cloud_service: Arc<dyn SearchCloudService>) -> Self {
    Self { cloud_service }
  }
}

#[async_trait]
impl SearchHandler for DocumentSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::Document
  }

  async fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> FlowyResult<Vec<SearchResultPB>> {
    let filter = match filter {
      Some(filter) => filter,
      None => return Ok(vec![]),
    };

    let workspace_id = match filter.workspace_id {
      Some(workspace_id) => workspace_id,
      None => return Ok(vec![]),
    };

    let results = self
      .cloud_service
      .document_search(&workspace_id, query)
      .await?;

    Ok(
      results
        .into_iter()
        .map(|result| SearchResultPB {
          index_type: IndexTypePB::Document,
          view_id: result.object_id.clone(),
          id: result.object_id,
          data: result.preview.unwrap_or_default(),
          icon: None,
          score: result.score,
          workspace_id: result.workspace_id,
        })
        .collect::<Vec<SearchResultPB>>(),
    )
  }

  /// Ignore for [DocumentSearchHandler]
  fn index_count(&self) -> u64 {
    0
  }
}
