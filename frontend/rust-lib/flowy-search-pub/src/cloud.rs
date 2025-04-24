pub use client_api::entity::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

#[async_trait]
pub trait SearchCloudService: Send + Sync + 'static {
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError>;

  async fn generate_search_summary(
    &self,
    workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError>;
}
