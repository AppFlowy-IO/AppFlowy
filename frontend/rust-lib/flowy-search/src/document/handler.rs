use std::sync::Arc;

use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;

use crate::{
  entities::{IndexTypePB, ResultIconPB, ResultIconTypePB, SearchFilterPB, SearchResultPB},
  services::manager::{SearchHandler, SearchType},
};

pub struct DocumentSearchHandler {
  pub cloud_service: Arc<dyn SearchCloudService>,
  pub folder_manager: Arc<FolderManager>,
}

impl DocumentSearchHandler {
  pub fn new(
    cloud_service: Arc<dyn SearchCloudService>,
    folder_manager: Arc<FolderManager>,
  ) -> Self {
    Self {
      cloud_service,
      folder_manager,
    }
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

    // Grab view cache from MutexFolder
    let mutex_folder = self.folder_manager.get_mutex_folder();
    if let Some(folder) = mutex_folder.read().as_ref() {
      let mut views = folder.views.get_all_views().into_iter();

      let mut search_results: Vec<SearchResultPB> = vec![];

      for result in results {
        // If there is no View for the result, we don't add it to the results
        if let Some(view) = views.find(|v| v.id == result.object_id) {
          // If possible we will extract the icon to display for the result
          let icon: Option<ResultIconPB> = match view.icon.clone() {
            Some(view_icon) => Some(ResultIconPB::from(view_icon)),
            None => {
              let view_layout_ty: i64 = view.layout.clone().into();
              Some(ResultIconPB {
                ty: ResultIconTypePB::Icon,
                value: view_layout_ty.to_string(),
              })
            },
          };

          search_results.push(SearchResultPB {
            index_type: IndexTypePB::Document,
            view_id: result.object_id.clone(),
            id: result.object_id.clone(),
            data: view.name.clone(),
            icon,
            // We reverse the score, the cloud search score is based on
            // 1 being the worst result, and closer to 0 being good result, that is
            // the opposite of local search.
            score: 1.0 - result.score,
            workspace_id: result.workspace_id,
            preview: result.preview,
          });
        }
      }

      return Ok(search_results);
    }

    Err(FlowyError::internal().with_context("Failed to get view cache in DocumentSearchHandler"))
  }

  /// Ignore for [DocumentSearchHandler]
  fn index_count(&self) -> u64 {
    0
  }
}
