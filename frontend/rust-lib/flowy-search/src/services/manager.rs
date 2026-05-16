use crate::document::local_search_handler::DocumentLocalSearchHandler;
use crate::entities::{SearchResponsePB, SearchStatePB};
use allo_isolate::Isolate;
use arc_swap::ArcSwapOption;
use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use futures::Sink;
use lib_infra::async_trait::async_trait;
use lib_infra::isolate_stream::{IsolateSink, SinkExt};
use std::pin::Pin;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tokio_stream::{self, Stream, StreamExt};
use tracing::{error, info, trace};
use uuid::Uuid;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub enum SearchType {
  Folder,
  DocumentCloud,
  DocumentLocal,
}

#[async_trait]
pub trait SearchHandler: Send + Sync + 'static {
  /// returns the type of search this handler is responsible for
  fn search_type(&self) -> SearchType;

  /// performs a search and returns a stream of results
  async fn perform_search(
    &self,
    query: String,
    workspace_id: &Uuid,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>>;
}

/// The [SearchManager] is used to inject multiple [SearchHandler]'s
/// to delegate a search to all relevant handlers, and stream the result
/// to the client until the query has been fully completed.
///
pub struct SearchManager {
  handlers: Arc<DashMap<SearchType, Arc<dyn SearchHandler>>>,
  current_search: Arc<tokio::sync::Mutex<Option<i64>>>,
  workspace_id: ArcSwapOption<Uuid>,
}

impl SearchManager {
  pub fn new(handlers: Vec<Arc<dyn SearchHandler>>) -> Self {
    let handlers: DashMap<SearchType, Arc<dyn SearchHandler>> = handlers
      .into_iter()
      .map(|handler| (handler.search_type(), handler))
      .collect();

    Self {
      handlers: Arc::new(handlers),
      current_search: Arc::new(tokio::sync::Mutex::new(None)),
      workspace_id: Default::default(),
    }
  }

  pub fn get_handler(&self, search_type: SearchType) -> Option<Arc<dyn SearchHandler>> {
    self.handlers.get(&search_type).map(|h| h.value().clone())
  }

  fn create_local_document_search(&self, state: Option<Weak<RwLock<DocumentTantivyState>>>) {
    if let Some(state) = state {
      let handler = DocumentLocalSearchHandler::new(state);
      info!("[Tanvity] create local document search handler");
      self
        .handlers
        .insert(SearchType::DocumentLocal, Arc::new(handler));
    } else {
      error!("[Tanvity] Failed to create local document search handler");
    }
  }

  pub async fn on_launch_if_authenticated(
    &self,
    workspace_id: &Uuid,
    state: Option<Weak<RwLock<DocumentTantivyState>>>,
  ) {
    self.workspace_id.store(Some(Arc::new(*workspace_id)));
    self.create_local_document_search(state);
  }

  pub async fn initialize_after_sign_in(
    &self,
    workspace_id: &Uuid,
    state: Option<Weak<RwLock<DocumentTantivyState>>>,
  ) {
    self.workspace_id.store(Some(Arc::new(*workspace_id)));
    self.create_local_document_search(state);
  }

  pub async fn initialize_after_sign_up(
    &self,
    workspace_id: &Uuid,
    state: Option<Weak<RwLock<DocumentTantivyState>>>,
  ) {
    self.workspace_id.store(Some(Arc::new(*workspace_id)));
    self.create_local_document_search(state);
  }

  pub async fn initialize_after_open_workspace(
    &self,
    workspace_id: &Uuid,
    state: Option<Weak<RwLock<DocumentTantivyState>>>,
  ) {
    self.workspace_id.store(Some(Arc::new(*workspace_id)));
    self.create_local_document_search(state);
  }

  pub async fn perform_search(&self, query: String, stream_port: i64, search_id: i64) {
    let sink = IsolateSink::new(Isolate::new(stream_port));
    self.perform_search_with_sink(query, sink, search_id).await;
  }

  pub async fn perform_search_with_sink<S>(&self, query: String, mut sink: S, search_id: i64)
  where
    S: Sink<Vec<u8>> + Clone + Send + Unpin + 'static,
    S::Error: std::fmt::Display,
  {
    let workspace_id = match self.workspace_id.load_full() {
      Some(id) => id,
      None => {
        error!("No workspace id found");
        return;
      },
    };

    // Check and update current search
    {
      let mut current = self.current_search.lock().await;
      if current.map_or(false, |cur| cur > search_id) {
        return;
      }
      *current = Some(search_id);
    }

    info!("[Search] perform search: {}", query);
    if query.is_empty() {
      let resp = SearchStatePB {
        response: None,
        search_id: search_id.to_string(),
      };
      if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
        if let Err(err) = sink.send(data).await {
          error!("Failed to send empty search result: {}", err);
        }
      }
      return;
    }

    let handlers = self.handlers.clone();
    let current_search = self.current_search.clone();
    let mut join_handles = vec![];

    for handler in handlers.iter().map(|entry| entry.value().clone()) {
      let mut sink_clone = sink.clone();
      let query_clone = query.clone();
      let current_search_clone = current_search.clone();
      let workspace_id_clone = workspace_id.clone();

      let handle = tokio::spawn(async move {
        // Check if still current search before starting
        if !is_current_search(&current_search_clone, search_id).await {
          trace!("[Search] cancel search: {}", query_clone);
          return;
        }

        let mut stream = handler
          .perform_search(query_clone.clone(), &workspace_id_clone)
          .await;

        while let Some(Ok(search_result)) = stream.next().await {
          if !is_current_search(&current_search_clone, search_id).await {
            trace!("[Search] perform search cancel: {}", query_clone);
            return;
          }

          let resp = SearchStatePB {
            response: Some(search_result),
            search_id: search_id.to_string(),
          };

          if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
            if let Err(err) = sink_clone.send(data).await {
              error!("Failed to send search result: {}", err);
              break;
            }
          }
        }

        // Send completion message
        if is_current_search(&current_search_clone, search_id).await {
          let resp = SearchStatePB {
            response: None,
            search_id: search_id.to_string(),
          };
          if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
            let _ = sink_clone.send(data).await;
          }
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
  current_search: &Arc<tokio::sync::Mutex<Option<i64>>>,
  search_id: i64,
) -> bool {
  let current = current_search.lock().await;
  match *current {
    None => true,
    Some(c) => c == search_id,
  }
}
