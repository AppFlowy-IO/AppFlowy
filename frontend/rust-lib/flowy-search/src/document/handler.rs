use flowy_error::FlowyResult;
use flowy_folder::{manager::FolderManager, ViewLayout};
use flowy_search_pub::cloud::SearchCloudService;
use lib_infra::async_trait::async_trait;
use std::str::FromStr;
use std::sync::Arc;
use tracing::{trace, warn};
use uuid::Uuid;

use crate::entities::{CreateSearchResultPBArgs, SearchResultPB, SearchSourcePB, SearchSummaryPB};
use crate::{
  entities::{IndexTypePB, ResultIconPB, ResultIconTypePB, SearchFilterPB, SearchResponseItemPB},
  services::manager::{SearchHandler, SearchType},
};

pub struct DocumentSearchHandler {
  pub cloud_service: Arc<dyn SearchCloudService>,
  pub folder_manager: Arc<FolderManager>,
}

impl DocumentSearchHandler {
  pub fn new(
    cloud_service: Arc<dyn SearchCloudService>,
    folder_manager: Arc<FolderManager>,
  ) -> Self {
    Self {
      cloud_service,
      folder_manager,
    }
  }
}

#[async_trait]
impl SearchHandler for DocumentSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::Document
  }

  async fn perform_search(
    &self,
    query: String,
    filter: Option<SearchFilterPB>,
  ) -> FlowyResult<SearchResultPB> {
    let filter = match filter {
      Some(filter) => filter,
      None => return Ok(CreateSearchResultPBArgs::default().build().unwrap()),
    };

    let workspace_id = match filter.workspace_id {
      Some(workspace_id) => workspace_id,
      None => return Ok(CreateSearchResultPBArgs::default().build().unwrap()),
    };

    let workspace_id = Uuid::from_str(&workspace_id)?;
    let result = self
      .cloud_service
      .document_search(&workspace_id, query)
      .await?;
    trace!("[Search] remote search results: {:?}", result);

    // Grab all views from folder cache
    // Notice that `get_all_view_pb` returns Views that don't include trashed and private views
    let views = self.folder_manager.get_all_views_pb().await?;
    let mut items: Vec<SearchResponseItemPB> = vec![];
    let mut summaries: Vec<SearchSummaryPB> = vec![];

    for item in result.items {
      if let Some(view) = views.iter().find(|v| v.id == item.object_id.to_string()) {
        // If there is no View for the result, we don't add it to the results
        // If possible we will extract the icon to display for the result
        let icon: Option<ResultIconPB> = match view.icon.clone() {
          Some(view_icon) => Some(ResultIconPB::from(view_icon)),
          None => {
            let view_layout_ty: i64 = ViewLayout::from(view.layout.clone()).into();
            Some(ResultIconPB {
              ty: ResultIconTypePB::Icon,
              value: view_layout_ty.to_string(),
            })
          },
        };

        items.push(SearchResponseItemPB {
          index_type: IndexTypePB::Document,
          view_id: item.object_id.to_string(),
          id: item.object_id.to_string(),
          data: view.name.clone(),
          icon,
          score: item.score,
          workspace_id: item.workspace_id.to_string(),
          preview: item.preview,
        });
      } else {
        warn!("No view found for search result: {:?}", item);
      }
    }

    for summary in result.summary {
      let metadata = summary.metadata.as_object().and_then(|object| {
        let id = object
          .get("id")
          .and_then(|v| v.as_str())
          .filter(|s| !s.is_empty())
          .map(|s| s.to_string())?;
        let source = object
          .get("source")
          .and_then(|v| v.as_str())
          .filter(|s| !s.is_empty())
          .map(|s| s.to_string())?;

        Some(SearchSourcePB { id, source })
      });

      summaries.push(SearchSummaryPB {
        content: summary.content,
        metadata,
      })
    }

    trace!("[Search] showing results: {:?}", items);
    Ok(
      CreateSearchResultPBArgs::default()
        .items(items)
        .summaries(summaries)
        .build()
        .unwrap(),
    )
  }
}
