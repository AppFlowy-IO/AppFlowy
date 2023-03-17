mod database_ref_indexing;
mod database_rev_struct_migration;

use crate::manager::DatabaseUser;
use crate::services::persistence::database_ref::DatabaseRefIndexer;
use crate::services::persistence::migration::database_ref_indexing::{
  get_all_database_ids, indexing_database_view_refs,
};
use crate::services::persistence::migration::database_rev_struct_migration::migration_database_rev_struct;
use flowy_error::FlowyResult;
use std::sync::Arc;

pub(crate) struct DatabaseMigration {
  #[allow(dead_code)]
  user: Arc<dyn DatabaseUser>,
  database_ref_indexer: Arc<DatabaseRefIndexer>,
}

impl DatabaseMigration {
  pub fn new(user: Arc<dyn DatabaseUser>, database_ref_indexer: Arc<DatabaseRefIndexer>) -> Self {
    Self {
      user,
      database_ref_indexer,
    }
  }

  pub async fn run(&self, user_id: &str) -> FlowyResult<()> {
    let pool = self.user.db_pool()?;
    let database_ids = get_all_database_ids(pool.clone()).await?;
    migration_database_rev_struct(user_id, &database_ids, pool.clone()).await?;
    let _ = indexing_database_view_refs(
      user_id,
      &database_ids,
      self.user.clone(),
      self.database_ref_indexer.clone(),
    )
    .await;
    Ok(())
  }
}
