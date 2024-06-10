use client_api::entity::search_dto::SearchDocumentResponseItem;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

#[async_trait]
pub trait SearchCloudService: Send + Sync + 'static {
  async fn document_search(
    &self,
    workspace_id: &str,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError>;
}
