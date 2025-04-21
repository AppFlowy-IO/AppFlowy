use crate::af_cloud::AFServer;
use flowy_ai_pub::cloud::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub(crate) struct AFCloudSearchCloudServiceImpl<T> {
  pub inner: T,
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
    let client = self.inner.try_get_client()?;
    let result = client
      .search_documents(workspace_id, &query, 10, DEFAULT_PREVIEW, None)
      .await?;

    Ok(result)
  }

  async fn generate_search_summary(
    &self,
    workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError> {
    let client = self.inner.try_get_client()?;
    let result = client
      .generate_search_summary(workspace_id, &query, search_results)
      .await?;

    Ok(result)
  }
}
