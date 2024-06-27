use flowy_folder::manager::FolderManager;
use flowy_search::document::handler::DocumentSearchHandler;
use flowy_search::folder::handler::FolderSearchHandler;
use flowy_search::folder::indexer::FolderIndexManagerImpl;
use flowy_search::services::manager::SearchManager;
use flowy_search_pub::cloud::SearchCloudService;
use std::sync::Arc;

pub struct SearchDepsResolver();
impl SearchDepsResolver {
  pub async fn resolve(
    folder_indexer: Arc<FolderIndexManagerImpl>,
    cloud_service: Arc<dyn SearchCloudService>,
    folder_manager: Arc<FolderManager>,
  ) -> Arc<SearchManager> {
    let folder_handler = Arc::new(FolderSearchHandler::new(folder_indexer));
    let document_handler = Arc::new(DocumentSearchHandler::new(
      cloud_service,
      folder_manager.clone(),
    ));
    Arc::new(SearchManager::new(
      folder_manager,
      vec![folder_handler, document_handler],
    ))
  }
}
