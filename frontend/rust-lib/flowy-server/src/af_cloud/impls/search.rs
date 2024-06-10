use client_api::entity::search_dto::SearchDocumentResponseItem;
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudSearchCloudServiceImpl<T> {
  pub inner: T,
}

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
    let result = client.search_documents(workspace_id, &query, 10, 0).await?;
    Ok(result)
  }
}
