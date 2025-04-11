use client_api::entity::search_dto::SearchResult;
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

use crate::af_cloud::AFServer;

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
  ) -> Result<SearchResult, FlowyError> {
    let client = self.inner.try_get_client()?;
    let result = client
      .search_documents(workspace_id, &query, 10, DEFAULT_PREVIEW)
      .await?;

    Ok(result)
  }
}
