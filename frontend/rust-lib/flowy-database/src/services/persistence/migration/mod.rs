mod database_ref_indexing;
mod database_rev_struct_migration;

use crate::manager::DatabaseUser;
use crate::services::persistence::database_ref::DatabaseRefIndexer;
use crate::services::persistence::migration::database_ref_indexing::indexing_database_view_refs;
use crate::services::persistence::migration::database_rev_struct_migration::migration_database_rev_struct;
use crate::services::persistence::DatabaseDBConnection;
use flowy_error::FlowyResult;
use std::sync::Arc;

pub(crate) struct DatabaseMigration {
  #[allow(dead_code)]
  user: Arc<dyn DatabaseUser>,
  database: Arc<dyn DatabaseDBConnection>,
  database_ref_indexer: Arc<DatabaseRefIndexer>,
}

impl DatabaseMigration {
  pub fn new(
    user: Arc<dyn DatabaseUser>,
    database: Arc<dyn DatabaseDBConnection>,
    database_ref_indexer: Arc<DatabaseRefIndexer>,
  ) -> Self {
    Self {
      user,
      database,
      database_ref_indexer,
    }
  }

  pub async fn run(&self, user_id: &str) -> FlowyResult<()> {
    let _ = indexing_database_view_refs(
      user_id,
      self.user.clone(),
      self.database_ref_indexer.clone(),
    )
    .await;
    Ok(())
  }

  #[allow(dead_code)]
  pub async fn database_rev_struct_migration(&self, grid_id: &str) -> FlowyResult<()> {
    let user_id = self.user.user_id()?;
    let pool = self.database.get_db_pool()?;
    migration_database_rev_struct(&user_id, grid_id, pool).await?;
    Ok(())
  }
}
