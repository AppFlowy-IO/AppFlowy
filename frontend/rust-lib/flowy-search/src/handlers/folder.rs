use crate::services::manager::ISearchHandler;

pub struct FolderSearchHandler {}

impl FolderSearchHandler {
  pub fn new() -> Self {
    Self {}
  }
}

impl ISearchHandler for FolderSearchHandler {
  fn perform_search(&self, _query: String) {
    tracing::error!("FOLDER SEARCH HANDLER");
  }
}

// TODO:
// Consider if there is a need to cache the previous results, and individually manage it
//
