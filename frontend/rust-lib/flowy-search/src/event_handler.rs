use std::sync::{Arc, Weak};

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{AFPluginData, AFPluginState};

use crate::{entities::SearchQueryPB, services::manager::SearchManager};

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
) -> Result<(), FlowyError> {
  let query = data.into_inner();
  let manager = upgrade_manager(manager)?;
  manager.perform_search(query.search, query.filter, query.channel);

  Ok(())
}
