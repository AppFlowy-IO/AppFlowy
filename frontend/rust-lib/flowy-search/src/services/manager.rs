use std::sync::Arc;

use flowy_error::FlowyResult;
use lib_dispatch::prelude::af_spawn;
use tokio::{sync::broadcast, task::spawn_blocking};

use crate::entities::{SearchResultNotificationPB, SearchResultPB};

use super::notifier::{SearchNotifier, SearchResultChanged, SearchResultReceiverRunner};

pub trait SearchHandler: Send + Sync + 'static {
  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>>;
}

/// The [SearchManager] is used to inject multiple [SearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub handlers: Vec<Arc<dyn SearchHandler>>,
  notifier: SearchNotifier,
}

impl SearchManager {
  pub fn new(handlers: Vec<Arc<dyn SearchHandler>>) -> Self {
    // Initialize Search Notifier
    let (notifier, _) = broadcast::channel(100);
    af_spawn(SearchResultReceiverRunner(Some(notifier.subscribe())).run());

    Self { handlers, notifier }
  }

  pub fn perform_search(&self, query: String) {
    let mut sends: usize = 0;
    let max: usize = self.handlers.len();
    let handlers = self.handlers.clone();

    for handler in handlers {
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
