use crate::manager::DatabaseUser;
use crate::services::database_view::make_database_view_revision_pad;
use crate::services::persistence::database_ref::DatabaseRefIndexer;

use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KV;

use flowy_sqlite::{
  prelude::*,
  schema::{grid_view_rev_table, grid_view_rev_table::dsl},
};
use lib_infra::util::md5;

use std::sync::Arc;

const DATABASE_REF_INDEXING: &str = "database_ref_indexing";

pub async fn indexing_database_view_refs(
  user_id: &str,
  user: Arc<dyn DatabaseUser>,
  database_ref_indexer: Arc<DatabaseRefIndexer>,
) -> FlowyResult<()> {
  let key = md5(format!("{}{}", user_id, DATABASE_REF_INDEXING));
  if KV::get_bool(&key) {
    return Ok(());
  }
  tracing::trace!("Indexing database view refs");
  let pool = user.db_pool()?;
  let view_ids = dsl::grid_view_rev_table
    .select(grid_view_rev_table::object_id)
    .distinct()
    .load::<String>(&*pool.get().map_err(|e| FlowyError::internal().context(e))?)?;

  for view_id in view_ids {
    if let Ok((pad, _)) = make_database_view_revision_pad(&view_id, user.clone()).await {
      tracing::trace!(
        "Indexing database:{} with view:{}",
        pad.database_id,
        pad.view_id
      );
      let _ = database_ref_indexer.bind(&pad.database_id, &pad.view_id, true, &pad.name);
    }
  }

  KV::set_bool(&key, true);
  Ok(())
}
