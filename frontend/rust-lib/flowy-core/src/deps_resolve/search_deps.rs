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
  ) -> Arc<SearchManager> {
    let folder_handler = Arc::new(FolderSearchHandler::new(folder_indexer));
    let document_handler = Arc::new(DocumentSearchHandler::new(cloud_service));
    Arc::new(SearchManager::new(vec![folder_handler, document_handler]))
  }
}
