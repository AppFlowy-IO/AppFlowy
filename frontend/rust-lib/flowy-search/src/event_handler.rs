use std::sync::{Arc, Weak};

use crate::{entities::SearchQueryPB, services::manager::SearchManager};
use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{AFPluginData, AFPluginState};
use lib_infra::util::timestamp;

fn upgrade_manager(
  search_manager: AFPluginState<Weak<SearchManager>>,
) -> FlowyResult<Arc<SearchManager>> {
  let manager = search_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The SearchManager has already been dropped"))?;
  Ok(manager)
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn stream_search_handler(
  data: AFPluginData<SearchQueryPB>,
  manager: AFPluginState<Weak<SearchManager>>,
) -> Result<(), FlowyError> {
  let query = data.into_inner();
  let manager = upgrade_manager(manager)?;
  let search_id = query.search_id.parse::<i64>().unwrap_or(timestamp());
  manager
    .perform_search(query.search, query.stream_port, search_id)
    .await;

  Ok(())
}
