use std::sync::{Arc, Weak};

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::{
  entities::{RepeatedSearchResultPB, SearchQueryPB, SearchResultPB},
  services::manager::SearchManager,
};

fn upgrade_manager(
  search_manager: AFPluginState<Weak<SearchManager>>,
) -> FlowyResult<Arc<SearchManager>> {
  let manager = search_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The SearchManager has already been dropped"))?;
  Ok(manager)
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn search_handler(
  data: AFPluginData<SearchQueryPB>,
  manager: AFPluginState<Weak<SearchManager>>,
) -> DataResult<RepeatedSearchResultPB, FlowyError> {
  let query = data.into_inner();
  let manager = upgrade_manager(manager);

  match manager {
    Ok(manager) => {
      manager.perform_search(query.search);
    },
    Err(_) => {},
  }

  let res = RepeatedSearchResultPB {
    items: vec![
      SearchResultPB {
        index_type: "index_type".to_owned(),
        view_id: "view_id".to_owned(),
        id: "id".to_owned(),
        data: "data".to_owned(),
      },
      SearchResultPB {
        index_type: "index_type_2".to_owned(),
        view_id: "view_id_2".to_owned(),
        id: "id_2".to_owned(),
        data: "data_2".to_owned(),
      },
    ],
  };
  data_result_ok(res)
}
