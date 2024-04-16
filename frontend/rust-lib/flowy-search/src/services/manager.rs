use std::collections::HashMap;
use std::sync::Arc;

use flowy_error::FlowyResult;
use lib_dispatch::prelude::af_spawn;
use tokio::{sync::broadcast, task::spawn_blocking};

use crate::entities::{SearchResultNotificationPB, SearchResultPB};

use super::notifier::{SearchNotifier, SearchResultChanged, SearchResultReceiverRunner};

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub enum SearchType {
  Folder,
}

pub trait SearchHandler: Send + Sync + 'static {
  /// returns the type of search this handler is responsible for
  fn search_type(&self) -> SearchType;
  /// performs a search and returns the results
  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>>;
  /// returns the number of indexed objects
  fn index_count(&self) -> u64;
}

/// The [SearchManager] is used to inject multiple [SearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub handlers: HashMap<SearchType, Arc<dyn SearchHandler>>,
  notifier: SearchNotifier,
}

impl SearchManager {
  pub fn new(handlers: Vec<Arc<dyn SearchHandler>>) -> Self {
    let handlers: HashMap<SearchType, Arc<dyn SearchHandler>> = handlers
      .into_iter()
      .map(|handler| (handler.search_type(), handler))
      .collect();

    // Initialize Search Notifier
    let (notifier, _) = broadcast::channel(100);
    af_spawn(SearchResultReceiverRunner(Some(notifier.subscribe())).run());

    Self { handlers, notifier }
  }

  pub fn get_handler(&self, search_type: SearchType) -> Option<&Arc<dyn SearchHandler>> {
    self.handlers.get(&search_type)
  }

  pub fn perform_search(&self, query: String) {
    let mut sends: usize = 0;
    let max: usize = self.handlers.len();
    let handlers = self.handlers.clone();

    for (_, handler) in handlers {
      let q = query.clone();
      let notifier = self.notifier.clone();

      spawn_blocking(move || {
        let res = handler.perform_search(q);
        sends += 1;

        let close = sends == max;
        let items = res.unwrap_or_default();
        let notification = SearchResultNotificationPB {
          items,
          closed: close,
        };

        let _ = notifier.send(SearchResultChanged::SearchResultUpdate(notification));
      });
    }
  }
}
