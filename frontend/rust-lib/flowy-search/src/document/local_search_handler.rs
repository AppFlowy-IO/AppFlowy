use async_stream::stream;
use futures::Stream;
use std::pin::Pin;
use std::sync::Weak;
use tokio::sync::RwLock;
use tracing::{error, trace};
use uuid::Uuid;

use crate::entities::{
  CreateSearchResultPBArgs, LocalSearchResponseItemPB, RepeatedLocalSearchResponseItemPB,
  ResultIconPB, ResultIconTypePB, SearchResponsePB,
};
use crate::services::manager::{SearchHandler, SearchType};
use flowy_error::FlowyResult;
use flowy_search_pub::entities::TanvitySearchResponseItem;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use lib_infra::async_trait::async_trait;

pub struct DocumentLocalSearchHandler {
  state: Weak<RwLock<DocumentTantivyState>>,
}

impl DocumentLocalSearchHandler {
  pub fn new(state: Weak<RwLock<DocumentTantivyState>>) -> Self {
    Self { state }
  }
}

#[async_trait]
impl SearchHandler for DocumentLocalSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::DocumentLocal
  }

  async fn perform_search(
    &self,
    query: String,
    workspace_id: &Uuid,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>> {
    let workspace_id = *workspace_id;
    let state = self.state.clone();
    Box::pin(stream! {
      match state.upgrade() {
        None => {
          yield Ok(
            CreateSearchResultPBArgs::default()
              .local_search_result(None)
              .build()
              .unwrap(),
          );
        },
        Some(state) => {
          match state.read().await.search(&workspace_id, &query, None) {
            Ok(items) => {
              trace!("[Tanvity] local document search result: {:?}", items);
              if items.is_empty() {
                yield Ok(
                  CreateSearchResultPBArgs::default()
                    .local_search_result(None)
                    .build()
                    .unwrap(),
                );
              } else {
                let items = items.into_iter().map(tanvity_item_to_local_search_item).collect::<Vec<_>>();
                let search_result = RepeatedLocalSearchResponseItemPB { items };
                yield Ok(
                  CreateSearchResultPBArgs::default()
                    .local_search_result(Some(search_result))
                    .build()
                    .unwrap(),
                );
              }
            },
            Err(err) => error!("[Tantivy] Failed to search documents, {:?}", err),
          }
        }
      }
    })
  }
}

fn tanvity_item_to_local_search_item(item: TanvitySearchResponseItem) -> LocalSearchResponseItemPB {
  LocalSearchResponseItemPB {
    id: item.id,
    display_name: item.display_name,
    icon: item.icon.map(|icon| ResultIconPB {
      ty: ResultIconTypePB::from(icon.ty),
      value: icon.value,
    }),
    workspace_id: item.workspace_id,
  }
}
