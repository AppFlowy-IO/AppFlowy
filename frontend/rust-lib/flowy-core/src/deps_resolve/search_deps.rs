use flowy_search::folder::handler::FolderSearchHandler;
use flowy_search::folder::indexer::FolderIndexManagerImpl;
use flowy_search::services::manager::SearchManager;
use std::sync::Arc;

pub struct SearchDepsResolver();
impl SearchDepsResolver {
  pub async fn resolve(folder_indexer: Arc<FolderIndexManagerImpl>) -> Arc<SearchManager> {
    let folder_handler = Arc::new(FolderSearchHandler::new(folder_indexer));
    Arc::new(SearchManager::new(vec![folder_handler]))
  }
}
