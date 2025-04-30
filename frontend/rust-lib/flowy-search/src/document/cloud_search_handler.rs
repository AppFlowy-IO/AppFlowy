use crate::entities::{
  CreateSearchResultPBArgs, RepeatedSearchResponseItemPB, RepeatedSearchSummaryPB,
  SearchResponsePB, SearchSourcePB, SearchSummaryPB,
};
use crate::{
  entities::{ResultIconPB, ResultIconTypePB, SearchFilterPB, SearchResponseItemPB},
  services::manager::{SearchHandler, SearchType},
};
use async_stream::stream;
use flowy_error::FlowyResult;
use flowy_folder::entities::ViewPB;
use flowy_folder::{manager::FolderManager, ViewLayout};
use flowy_search_pub::cloud::{SearchCloudService, SearchResult};
use lib_infra::async_trait::async_trait;
use std::pin::Pin;
use std::str::FromStr;
use std::sync::Arc;
use tokio_stream::{self, Stream};
use tracing::{trace, warn};
use uuid::Uuid;

pub struct DocumentCloudSearchHandler {
  pub cloud_service: Arc<dyn SearchCloudService>,
  pub folder_manager: Arc<FolderManager>,
}

impl DocumentCloudSearchHandler {
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
impl SearchHandler for DocumentCloudSearchHandler {
  fn search_type(&self) -> SearchType {
    SearchType::DocumentCloud
  }

  async fn perform_search(
    &self,
    query: String,
    workspace_id: &Uuid,
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResponsePB>> + Send + 'static>> {
    let cloud_service = self.cloud_service.clone();
    let folder_manager = self.folder_manager.clone();
    let workspace_id = *workspace_id;

    Box::pin(stream! {
      // Retrieve all available views.
      let views = match folder_manager.get_all_views_pb().await {
        Ok(views) => views,
        Err(e) => {
          yield Err(e);
          return;
        }
      };

      // Execute document search.
      yield Ok(
        CreateSearchResultPBArgs::default().searching(true)
          .build()
          .unwrap(),
      );

      let result_items = match cloud_service.document_search(&workspace_id, query.clone()).await {
        Ok(items) => items,
        Err(e) => {
          yield Err(e);
          return;
        }
      };
      trace!("[Search] search result: {:?}", result_items);

      // Prepare input for search summary generation.
      let summary_input: Vec<SearchResult> = result_items
        .iter()
        .map(|v| SearchResult {
          object_id: v.object_id,
          content: v.content.clone(),
        })
        .collect();

      // Build search response items.
      let mut items: Vec<SearchResponseItemPB> = Vec::new();
      for item in &result_items {
        if let Some(view) = views.iter().find(|v| v.id == item.object_id.to_string()) {
          items.push(SearchResponseItemPB {
            id: item.object_id.to_string(),
            display_name: view.name.clone(),
            icon: extract_icon(view),
            workspace_id: item.workspace_id.to_string(),
            content: item.content.clone()}
          );
        } else {
          warn!("No view found for search result: {:?}", item);
        }
      }

      // Yield primary search result.
      let search_result = RepeatedSearchResponseItemPB { items };
      yield Ok(
        CreateSearchResultPBArgs::default()
          .searching(false)
          .search_result(Some(search_result))
          .generating_ai_summary(!result_items.is_empty())
          .build()
          .unwrap(),
      );

      if result_items.is_empty() {
        return;
      }

      // Generate and yield search summary.
      match cloud_service.generate_search_summary(&workspace_id, query.clone(), summary_input).await {
        Ok(summary_result) => {
          trace!("[Search] search summary: {:?}", summary_result);
          let summaries: Vec<SearchSummaryPB> = summary_result
            .summaries
            .into_iter()
            .map(|v| {
              let sources: Vec<SearchSourcePB> = v.sources
                .iter()
                .flat_map(|id| {
                  views.iter().find(|v| v.id == id.to_string()).map(|view| SearchSourcePB {
                      id: id.to_string(),
                      display_name: view.name.clone(),
                      icon: extract_icon(view),
                    })
                })
                .collect();

              SearchSummaryPB { content: v.content, sources, highlights: v.highlights }
            })
            .collect();

          let summary_result = RepeatedSearchSummaryPB { items: summaries };
          yield Ok(
            CreateSearchResultPBArgs::default()
              .search_summary(Some(summary_result))
              .generating_ai_summary(false)
              .build()
              .unwrap(),
          );
        }
        Err(e) => {
          warn!("Failed to generate search summary: {:?}", e);
          yield Ok(
            CreateSearchResultPBArgs::default()
              .generating_ai_summary(false)
              .build()
              .unwrap(),
          );
        }
      }
    })
  }
}

fn extract_icon(view: &ViewPB) -> Option<ResultIconPB> {
  match view.icon.clone() {
    Some(view_icon) => Some(ResultIconPB::from(view_icon)),
    None => {
      let view_layout_ty: i64 = ViewLayout::from(view.layout.clone()).into();
      Some(ResultIconPB {
        ty: ResultIconTypePB::Icon,
        value: view_layout_ty.to_string(),
      })
    },
  }
}
