use crate::af_cloud::AFServer;
use crate::util::tanvity_local_search;
use flowy_ai_pub::cloud::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use lib_infra::async_trait::async_trait;
use std::sync::Weak;
use tokio::sync::RwLock;
use tracing::trace;
use uuid::Uuid;

pub(crate) struct AFCloudSearchCloudServiceImpl<T> {
  pub server: T,
  pub state: Option<Weak<RwLock<DocumentTantivyState>>>,
}

const DEFAULT_PREVIEW: u32 = 80;

#[async_trait]
impl<T> SearchCloudService for AFCloudSearchCloudServiceImpl<T>
where
  T: AFServer,
{
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    let client = self.server.try_get_client()?;
    let result = client
      .search_documents(workspace_id, &query, 10, DEFAULT_PREVIEW, None)
      .await?;

    if !result.is_empty() {
      return Ok(result);
    }

    trace!("[Search] Local AI search returned no results, falling back to local search");
    let items = tanvity_local_search(&self.state, workspace_id, &query, None, 10, 0.4)
      .await
      .unwrap_or_default();
    Ok(items)
  }

  async fn generate_search_summary(
    &self,
    workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError> {
    let client = self.server.try_get_client()?;
    let result = client
      .generate_search_summary(workspace_id, &query, search_results)
      .await?;

    Ok(result)
  }
}
