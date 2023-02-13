use crate::manager::DatabaseUser;
use crate::services::persistence::rev_sqlite::SQLiteDatabaseRevisionPersistence;
use crate::services::persistence::GridDatabase;
use bytes::Bytes;
use flowy_client_sync::client_database::{
  make_database_rev_json_str, DatabaseOperationsBuilder, DatabaseRevisionPad,
};
use flowy_error::FlowyResult;
use flowy_revision::reset::{RevisionResettable, RevisionStructReset};
use flowy_sqlite::kv::KV;
use grid_model::DatabaseRevision;
use lib_infra::util::md5;
use revision_model::Revision;
use std::sync::Arc;

const V1_MIGRATION: &str = "GRID_V1_MIGRATION";

pub(crate) struct DatabaseMigration {
  user: Arc<dyn DatabaseUser>,
  database: Arc<dyn GridDatabase>,
}

impl DatabaseMigration {
  pub fn new(user: Arc<dyn DatabaseUser>, database: Arc<dyn GridDatabase>) -> Self {
    Self { user, database }
  }

  pub async fn run_v1_migration(&self, grid_id: &str) -> FlowyResult<()> {
    let user_id = self.user.user_id()?;
    let key = migration_flag_key(&user_id, V1_MIGRATION, grid_id);
    if KV::get_bool(&key) {
      return Ok(());
    }
    self.migration_grid_rev_struct(grid_id).await?;
    tracing::trace!("Run grid:{} v1 migration", grid_id);
    KV::set_bool(&key, true);
    Ok(())
  }

  pub async fn migration_grid_rev_struct(&self, grid_id: &str) -> FlowyResult<()> {
    let object = GridRevisionResettable {
      grid_id: grid_id.to_owned(),
    };
    let user_id = self.user.user_id()?;
    let pool = self.database.db_pool()?;
    let disk_cache = SQLiteDatabaseRevisionPersistence::new(&user_id, pool);
    let reset = RevisionStructReset::new(&user_id, object, Arc::new(disk_cache));
    reset.run().await
  }
}

fn migration_flag_key(user_id: &str, version: &str, grid_id: &str) -> String {
  md5(format!("{}{}{}", user_id, version, grid_id,))
}

pub struct GridRevisionResettable {
  grid_id: String,
}

impl RevisionResettable for GridRevisionResettable {
  fn target_id(&self) -> &str {
    &self.grid_id
  }

  fn reset_data(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
    let pad = DatabaseRevisionPad::from_revisions(revisions)?;
    let json = pad.json_str()?;
    let bytes = DatabaseOperationsBuilder::new()
      .insert(&json)
      .build()
      .json_bytes();
    Ok(bytes)
  }

  fn default_target_rev_str(&self) -> FlowyResult<String> {
    let grid_rev = DatabaseRevision::default();
    let json = make_database_rev_json_str(&grid_rev)?;
    Ok(json)
  }

  fn read_record(&self) -> Option<String> {
    KV::get_str(self.target_id())
  }

  fn set_record(&self, record: String) {
    KV::set_str(self.target_id(), record);
  }
}
