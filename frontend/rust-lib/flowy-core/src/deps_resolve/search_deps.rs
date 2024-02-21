use flowy_search::folder::handler::FolderSearchHandler;
use flowy_search::folder::indexer::FolderIndexManager;
use flowy_search::services::manager::SearchManager;
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::sync::{Arc, Weak};

pub struct SearchDepsResolver();
impl SearchDepsResolver {
  pub async fn resolve(authenticate_user: Weak<AuthenticateUser>) -> Arc<SearchManager> {
    let folder_index_manager = FolderIndexManager::new(authenticate_user);
    let folder_handler = FolderSearchHandler::new(Box::new(folder_index_manager));

    Arc::new(SearchManager::new(vec![Arc::new(folder_handler)]))
  }
}
