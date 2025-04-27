use crate::entities::{SearchFilterPB, SearchResponsePB, SearchStatePB};
use allo_isolate::Isolate;
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;
use lib_infra::isolate_stream::{IsolateSink, SinkExt};
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::Arc;
use tokio_stream::{self, Stream, StreamExt};
use tracing::{error, trace};

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub enum SearchType {
  Folder,
  Document,
}

#[async_trait]
pub trait SearchHandler: Send + Sync + 'static {
  /// returns the type of search this handler is responsible for
  fn search_type(&self) -> SearchType;

  /// performs a search and returns a stream of results
  async fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>>;
}

/// The [SearchManager] is used to inject multiple [SearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  pub handlers: HashMap<SearchType, Arc<dyn SearchHandler>>,
  current_search: Arc<tokio::sync::Mutex<Option<String>>>,
}

impl SearchManager {
  pub fn new(handlers: Vec<Arc<dyn SearchHandler>>) -> Self {
    let handlers: HashMap<SearchType, Arc<dyn SearchHandler>> = handlers
      .into_iter()
      .map(|handler| (handler.search_type(), handler))
      .collect();

    Self {
      handlers,
      current_search: Arc::new(tokio::sync::Mutex::new(None)),
    }
  }

  pub fn get_handler(&self, search_type: SearchType) -> Option<&Arc<dyn SearchHandler>> {
    self.handlers.get(&search_type)
  }

  pub async fn perform_search(
    &self,
    query: String,
    stream_port: i64,
    filter: Option<SearchFilterPB>,
    search_id: String,
  ) {
    // Cancel previous search by updating current_search
    *self.current_search.lock().await = Some(search_id.clone());

    let handlers = self.handlers.clone();
    let sink = IsolateSink::new(Isolate::new(stream_port));
    let mut join_handles = vec![];
    let current_search = self.current_search.clone();

    tracing::info!("[Search] perform search: {}", query);
    for (_, handler) in handlers {
      let mut clone_sink = sink.clone();
      let query = query.clone();
      let filter = filter.clone();
      let search_id = search_id.clone();
      let current_search = current_search.clone();

      let handle = tokio::spawn(async move {
        if !is_current_search(&current_search, &search_id).await {
          trace!("[Search] cancel search: {}", query);
          return;
        }

        let mut stream = handler.perform_search(query.clone(), filter).await;
        while let Some(Ok(search_result)) = stream.next().await {
          if !is_current_search(&current_search, &search_id).await {
            trace!("[Search] discard search stream: {}", query);
            return;
          }

          let resp = SearchStatePB {
            response: Some(search_result),
            search_id: search_id.clone(),
          };
          if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
            if let Err(err) = clone_sink.send(data).await {
              error!("Failed to send search result: {}", err);
              break;
            }
          }
        }

        if !is_current_search(&current_search, &search_id).await {
          trace!("[Search] discard search result: {}", query);
          return;
        }

        let resp = SearchStatePB {
          response: None,
          search_id: search_id.clone(),
        };
        if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
          let _ = clone_sink.send(data).await;
        }
      });
      join_handles.push(handle);
    }
    futures::future::join_all(join_handles).await;
  }
}

impl Drop for SearchManager {
  fn drop(&mut self) {
    tracing::trace!("[Drop] drop search manager");
  }
}

async fn is_current_search(
  current_search: &Arc<tokio::sync::Mutex<Option<String>>>,
  search_id: &str,
) -> bool {
  let current = current_search.lock().await;
  current.as_deref() == Some(search_id)
}
