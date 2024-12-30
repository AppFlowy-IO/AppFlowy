use client_api::entity::search_dto::SearchDocumentResponseItem;
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudSearchCloudServiceImpl<T> {
  pub inner: T,
}

// The limit of what the score should be for results, used to
// filter out irrelevant results.
// https://community.openai.com/t/rule-of-thumb-cosine-similarity-thresholds/693670/5
const SCORE_LIMIT: f64 = 0.3;
const DEFAULT_PREVIEW: u32 = 80;

#[async_trait]
impl<T> SearchCloudService for AFCloudSearchCloudServiceImpl<T>
where
  T: AFServer,
{
  async fn document_search(
    &self,
    workspace_id: &str,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    let client = self.inner.try_get_client()?;
    let result = client
      .search_documents(workspace_id, &query, 10, DEFAULT_PREVIEW)
      .await?;

    // Filter out irrelevant results
    let result = result
      .into_iter()
      .filter(|r| r.score > SCORE_LIMIT)
      .collect();

    Ok(result)
  }
}
