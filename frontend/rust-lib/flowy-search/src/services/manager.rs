use lib_dispatch::prelude::af_spawn;
use tokio::sync::broadcast;

use super::{
  indexer::IndexManager,
  notifier::{SearchNotifier, SearchResultReceiverRunner},
};

pub trait ISearchHandler: Send + Sync + 'static {
  fn perform_search(&self, query: String);
  fn get_index_manager(&self) -> Box<dyn IndexManager>;
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
  pub fn new(handlers: Vec<Box<dyn ISearchHandler>>) -> Self {
    // Initialize Search Notifier
    let (notifier, _) = broadcast::channel(100);
    af_spawn(SearchResultReceiverRunner(Some(notifier.subscribe())).run());

    Self { handlers, notifier }
  }

  pub fn perform_search(&self, query: String) {
    for handler in &self.handlers {
      handler.perform_search(query.clone());
    }
  }
}
