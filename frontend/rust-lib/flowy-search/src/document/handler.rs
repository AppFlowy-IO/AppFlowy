use crate::entities::{
  CreateSearchResultPBArgs, RepeatedSearchResponseItemPB, RepeatedSearchSummaryPB, SearchResultPB,
  SearchSummaryPB,
};
use crate::{
  entities::{IndexTypePB, ResultIconPB, ResultIconTypePB, SearchFilterPB, SearchResponseItemPB},
  services::manager::{SearchHandler, SearchType},
};
use async_stream::stream;
use flowy_error::FlowyResult;
use flowy_folder::{manager::FolderManager, ViewLayout};
use flowy_search_pub::cloud::{SearchCloudService, SearchResult};
use lib_infra::async_trait::async_trait;
use std::pin::Pin;
use std::str::FromStr;
use std::sync::Arc;
use tokio_stream::{self, Stream};
use tracing::{trace, warn};
use uuid::Uuid;

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
  ) -> Pin<Box<dyn Stream<Item = FlowyResult<SearchResultPB>> + Send + 'static>> {
    let cloud_service = self.cloud_service.clone();
    let folder_manager = self.folder_manager.clone();

    Box::pin(stream! {
      let filter = match filter {
        Some(f) => f,
        None => {
          yield Ok(CreateSearchResultPBArgs::default().build().unwrap());
          return;
        },
      };

      let workspace_id = match Uuid::from_str(&filter.workspace_id) {
        Ok(id) => id,
        Err(e) => {
          yield Err(e.into());
          return;
        }
      };

      let views = match folder_manager.get_all_views_pb().await {
        Ok(views) => views,
        Err(e) => {
          yield Err(e);
          return;
        },
      };

      let result_items = match cloud_service.document_search(&workspace_id, query.clone()).await {
        Ok(items) => items,
        Err(e) => {
          yield Err(e);
          return;
        },
      };

      let summary_input = result_items
        .iter()
        .map(|v| SearchResult {
          object_id: v.object_id,
          content: v.content.clone(),
        })
        .collect::<Vec<_>>();

      let mut items: Vec<SearchResponseItemPB> = Vec::new();
      for item in result_items.iter() {
        if let Some(view) = views.iter().find(|v| v.id == item.object_id.to_string()) {
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
            preview: item.preview.clone(),
          });
        } else {
          warn!("No view found for search result: {:?}", item);
        }
      }

      let search_result = RepeatedSearchResponseItemPB {
        items,
      };
      yield Ok(
        CreateSearchResultPBArgs::default()
          .search_result(Some(search_result))
          .build()
          .unwrap(),
      );

      // Search summary generation.
      match cloud_service.generate_search_summary(&workspace_id, query.clone(), summary_input).await {
        Ok(summary_result) => {
          trace!("[Search] search summary: {:?}", summary_result);
          let summaries: Vec<SearchSummaryPB> = summary_result
            .summaries
            .into_iter()
            .map(|v| {
              SearchSummaryPB { content: v.content, source_ids: v.sources.iter().map(|id| id.to_string()).collect() }
            })
            .collect();

          let summary_result = RepeatedSearchSummaryPB {
            items: summaries,
          };
          yield Ok(
            CreateSearchResultPBArgs::default()
              .search_summary(Some(summary_result))
              .build()
              .unwrap(),
          );
        }
        Err(e) => {
          warn!("Failed to generate search summary: {:?}", e);
        }
      }
    })
  }
}
