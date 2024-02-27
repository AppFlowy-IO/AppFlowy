use flowy_search::folder::handler::FolderSearchHandler;
use flowy_search::folder::indexer::FolderIndexManager;
use flowy_search::services::manager::SearchManager;
use std::sync::{Arc, Weak};

pub struct SearchDepsResolver();
impl SearchDepsResolver {
  pub async fn resolve(folder_indexer: Weak<FolderIndexManager>) -> Arc<SearchManager> {
    let folder_indexer = folder_indexer
      .upgrade()
      .expect("FolderIndexer is not available")
      .clone();

    let folder_handler = Arc::new(FolderSearchHandler::new(folder_indexer));

    Arc::new(SearchManager::new(vec![folder_handler]))
  }
}
