use super::indexer::FolderIndexManagerImpl;
use crate::entities::{
  CreateSearchResultPBArgs, RepeatedLocalSearchResponseItemPB, SearchResponsePB,
};
use crate::services::manager::{SearchHandler, SearchType};
use async_stream::stream;
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;
use std::pin::Pin;
use std::sync::Arc;
use tokio_stream::{self, Stream};
use uuid::Uuid;

pub struct FolderSearchHandler {
  pub index_manager: Arc<FolderIndexManagerImpl>,
}

impl FolderSearchHandler {
  pub fn new(index_manager: Arc<FolderIndexManagerImpl>) -> Self {
    Self { index_manager }
  }
}

#[async_trait]
impl SearchHandler for FolderSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::Folder
  }

  async fn perform_search(
    &self,
    query: String,
    workspace_id: &Uuid,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>> {
    let workspace_id = workspace_id.to_string();
    let index_manager = self.index_manager.clone();

    Box::pin(stream! {
        // Perform search (if search() returns a Result)
        let mut items = match index_manager.search(query).await {
            Ok(items) => items,
            Err(err) => {
                yield Err(err);
                return;
            }
        };

        items.retain(|result| result.workspace_id == workspace_id);

        // Build the search result.
        let search_result = RepeatedLocalSearchResponseItemPB {items};
        yield Ok(CreateSearchResultPBArgs::default().local_search_result(Some(search_result)).build().unwrap())
    })
  }
}
