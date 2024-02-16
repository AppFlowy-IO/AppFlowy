use lib_dispatch::prelude::af_spawn;
use tokio::sync::broadcast;

use crate::handlers::folder::FolderSearchHandler;

use super::notifier::{SearchNotifier, SearchResultReceiverRunner};

pub trait ISearchHandler: Send + Sync + 'static {
  fn perform_search(&self, query: String);
}

/// The [SearchManager] is used to inject multiple [ISearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub handlers: Vec<Box<dyn ISearchHandler>>,
  notifier: SearchNotifier,
}

impl SearchManager {
  pub fn new() -> Self {
    // Initialize Search Notifier
    let (notifier, _) = broadcast::channel(100);
    af_spawn(SearchResultReceiverRunner(Some(notifier.subscribe())).run());

    Self {
      handlers: vec![Box::new(FolderSearchHandler::new())],
      notifier,
    }
  }

  pub fn perform_search(&self, query: String) {
    for handler in &self.handlers {
      handler.perform_search(query.clone());
    }
  }
}
