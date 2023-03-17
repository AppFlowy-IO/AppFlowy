mod database_migration;
mod database_view_migration;
use crate::entities::LayoutTypePB;
use crate::manager::DatabaseUser;
use crate::services::persistence::database_ref::DatabaseRefs;
use crate::services::persistence::migration::database_migration::{
  is_database_rev_migrated, migration_database_rev_struct,
};
use crate::services::persistence::migration::database_view_migration::{
  is_database_view_migrated, migrate_database_view,
};
use database_model::LayoutRevision;
use flowy_error::FlowyResult;
use lib_infra::future::Fut;
use std::sync::Arc;

pub(crate) struct DatabaseMigration {
  #[allow(dead_code)]
  user: Arc<dyn DatabaseUser>,
  database_refs: Arc<DatabaseRefs>,
}

impl DatabaseMigration {
  pub fn new(user: Arc<dyn DatabaseUser>, database_refs: Arc<DatabaseRefs>) -> Self {
    Self {
      user,
      database_refs,
    }
  }

  pub async fn run(
    &self,
    user_id: &str,
    get_views_fn: Fut<Vec<(String, String, LayoutTypePB)>>,
  ) -> FlowyResult<()> {
    let pool = self.user.db_pool()?;

    if !is_database_view_migrated(user_id) || !is_database_rev_migrated(user_id) {
      let migrated_databases = get_views_fn
        .await
        .into_iter()
        .map(|(view_id, name, layout)| MigratedDatabase {
          view_id,
          name,
          layout: layout.into(),
        })
        .collect::<Vec<_>>();

      migration_database_rev_struct(user_id, &migrated_databases, pool.clone()).await?;

      let _ = migrate_database_view(
        user_id,
        self.database_refs.clone(),
        &migrated_databases,
        pool.clone(),
      )
      .await;
    }

    Ok(())
  }
}

#[derive(Debug, Clone)]
pub(crate) struct MigratedDatabase {
  pub(crate) view_id: String,
  pub(crate) name: String,
  pub(crate) layout: LayoutRevision,
}
