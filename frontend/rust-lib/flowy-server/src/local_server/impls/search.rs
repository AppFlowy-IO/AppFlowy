use crate::af_cloud::define::LoggedUser;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;
use std::sync::Arc;
use uuid::Uuid;

pub struct LocalSearchServiceImpl {
  #[allow(dead_code)]
  pub logged_user: Arc<dyn LoggedUser>,
  pub local_ai: Arc<LocalAIController>,
}

impl LocalSearchServiceImpl {}

#[async_trait]
impl SearchCloudService for LocalSearchServiceImpl {
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      if let Ok(scheduler) = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler() {
        match scheduler.search(workspace_id, &query).await {
          Ok(results) => return Ok(results),
          Err(err) => tracing::error!("Local AI search failed: {:?}", err),
        }
      } else {
        tracing::error!("Could not acquire local AI scheduler");
      }
    }

    Ok(Vec::new())
  }

  async fn generate_search_summary(
    &self,
    _workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      if let Ok(scheduler) = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler() {
        let setting = self.local_ai.get_local_ai_setting();
        match scheduler
          .generate_summary(&query, &setting.chat_model_name, search_results)
          .await
        {
          Ok(results) => return Ok(results),
          Err(err) => tracing::error!("Local AI search failed: {:?}", err),
        }
      } else {
        tracing::error!("Could not acquire local AI scheduler");
      }
    }
    Ok(SearchSummaryResult { summaries: vec![] })
  }
}
