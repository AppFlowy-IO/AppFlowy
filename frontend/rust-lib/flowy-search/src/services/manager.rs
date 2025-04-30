use crate::document::local_search_handler::{DocumentLocalSearchHandler, DocumentTantivyState};
use crate::entities::{SearchFilterPB, SearchResponsePB, SearchStatePB};
use allo_isolate::Isolate;
use arc_swap::ArcSwapOption;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;
use lib_infra::isolate_stream::{IsolateSink, SinkExt};
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tokio_stream::{self, Stream, StreamExt};
use tracing::{error, trace};
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
      self
        .handlers
        .insert(SearchType::DocumentLocal, Arc::new(handler));
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
    let mut current = self.current_search.lock().await;
    if current.map_or(false, |cur| cur > search_id) {
      return;
    }
    let workspace_id = self.workspace_id.load_full();
    if workspace_id.is_none() {
      error!("No workspace id found");
      return;
    }

    // Otherwise register this as the latest search
    *current = Some(search_id);
    drop(current);

    let handlers = self.handlers.clone();
    let sink = IsolateSink::new(Isolate::new(stream_port));
    let mut join_handles = vec![];
    let current_search = self.current_search.clone();
    let workspace_id = workspace_id.unwrap();

    tracing::info!("[Search] perform search: {}", query);
    for (_, search_handler) in self.handlers.iter().enumerate() {
      let mut clone_sink = sink.clone();
      let query = query.clone();
      let current_search = current_search.clone();
      let search_handler = search_handler.value().clone();

      let workspace_id = workspace_id.clone();
      let handle = tokio::spawn(async move {
        if !is_current_search(&current_search, search_id).await {
          trace!("[Search] cancel search: {}", query);
          return;
        }

        let mut stream = search_handler
          .perform_search(query.clone(), &workspace_id)
          .await;
        while let Some(Ok(search_result)) = stream.next().await {
          if !is_current_search(&current_search, search_id).await {
            trace!("[Search] perform search cancel: {}", query);
            return;
          }

          let resp = SearchStatePB {
            response: Some(search_result),
            search_id: search_id.to_string(),
          };
          if let Ok::<Vec<u8>, _>(data) = resp.try_into() {
            if let Err(err) = clone_sink.send(data).await {
              error!("Failed to send search result: {}", err);
              break;
            }
          }
        }

        if !is_current_search(&current_search, search_id).await {
          trace!("[Search] perform search cancel: {}", query);
          return;
        }

        let resp = SearchStatePB {
          response: None,
          search_id: search_id.to_string(),
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
  current_search: &Arc<tokio::sync::Mutex<Option<i64>>>,
  search_id: i64,
) -> bool {
  let current = current_search.lock().await;
  match *current {
    None => true,
    Some(c) => c == search_id,
  }
}
