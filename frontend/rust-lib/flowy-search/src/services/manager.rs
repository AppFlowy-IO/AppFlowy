use std::collections::HashMap;
use std::sync::Arc;

use super::notifier::{SearchNotifier, SearchResultChanged, SearchResultReceiverRunner};
use crate::entities::{SearchFilterPB, SearchResultNotificationPB, SearchResultPB};
use flowy_error::FlowyResult;
use flowy_folder::manager::FolderManager;
use lib_dispatch::prelude::af_spawn;
use lib_infra::async_trait::async_trait;
use tokio::sync::broadcast;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub enum SearchType {
  Folder,
  Document,
}

#[async_trait]
pub trait SearchHandler: Send + Sync + 'static {
  /// returns the type of search this handler is responsible for
  fn search_type(&self) -> SearchType;

  /// performs a search and returns the results
  async fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> FlowyResult<Vec<SearchResultPB>>;

  /// returns the number of indexed objects
  fn index_count(&self) -> u64;
}

/// The [SearchManager] is used to inject multiple [SearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub folder_manager: Arc<FolderManager>,
  pub handlers: HashMap<SearchType, Arc<dyn SearchHandler>>,
  notifier: SearchNotifier,
}

impl SearchManager {
  pub fn new(folder_manager: Arc<FolderManager>, handlers: Vec<Arc<dyn SearchHandler>>) -> Self {
    let handlers: HashMap<SearchType, Arc<dyn SearchHandler>> = handlers
      .into_iter()
      .map(|handler| (handler.search_type(), handler))
      .collect();

    // Initialize Search Notifier
    let (notifier, _) = broadcast::channel(100);
    af_spawn(SearchResultReceiverRunner(Some(notifier.subscribe())).run());

    Self {
      folder_manager,
      handlers,
      notifier,
    }
  }

  pub fn get_handler(&self, search_type: SearchType) -> Option<&Arc<dyn SearchHandler>> {
    self.handlers.get(&search_type)
  }

  pub fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
    channel: Option<String>,
  ) {
    let mutex_folder = self.folder_manager.get_mutex_folder();
    let guard = mutex_folder.read();
    let folder = match guard.as_ref() {
      Some(folder) => folder,
      None => {
        let notification = SearchResultNotificationPB {
          items: vec![],
          sends: 0 as u64,
          channel,
          query,
        };
        let _ = self
          .notifier
          .send(SearchResultChanged::SearchResultUpdate(notification));
        return;
      },
    };
    let private_views = self.folder_manager.get_view_ids_should_be_filtered(folder);
    tracing::warn!("Private views: {:?}", private_views);

    let max: usize = self.handlers.len();
    let handlers = self.handlers.clone();
    for (_, handler) in handlers {
      let q = query.clone();
      let f = filter.clone();
      let ch = channel.clone();
      let notifier = self.notifier.clone();
      let private_view_ids = private_views.clone();

      af_spawn(async move {
        let res = handler.perform_search(q.clone(), f).await;

        let items = res.unwrap_or_default();

        // Filter out any items which ID exists in private_views
        let items = items
          .into_iter()
          .filter(|item| !private_view_ids.contains(&item.id))
          .collect();

        let notification = SearchResultNotificationPB {
          items,
          sends: max as u64,
          channel: ch,
          query: q,
        };

        let _ = notifier.send(SearchResultChanged::SearchResultUpdate(notification));
      });
    }
  }
}
