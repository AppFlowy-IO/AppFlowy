use std::sync::Arc;

use flowy_error::FlowyResult;
use lib_dispatch::prelude::af_spawn;
use tokio::sync::broadcast;

use crate::entities::{SearchResultNotificationPB, SearchResultPB};

use super::notifier::{SearchNotifier, SearchResultChanged, SearchResultReceiverRunner};

pub trait ISearchHandler: Send + Sync + 'static {
  fn perform_search(&self, query: String) -> FlowyResult<Vec<SearchResultPB>>;
}

/// The [SearchManager] is used to inject multiple [ISearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub handlers: Vec<Arc<dyn ISearchHandler>>,
  notifier: SearchNotifier,
}

impl SearchManager {
  pub fn new(handlers: Vec<Arc<dyn ISearchHandler>>) -> Self {
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

      tokio::spawn(async move {
        let res = handler.perform_search(q);
        sends += 1;

        let close = sends == max;
        let notification: Option<SearchResultNotificationPB> = match res {
          Ok(results) => Some(SearchResultNotificationPB {
            items: results,
            closed: close,
          }),
          Err(_) => {
            if close {
              return Some(SearchResultNotificationPB {
                items: vec![],
                closed: true,
              });
            }

            None
          },
        };

        if let Some(notification) = notification {
          let _ = notifier.send(SearchResultChanged::SearchResultUpdate(notification));
        }

        None
      });
    }
  }
}
