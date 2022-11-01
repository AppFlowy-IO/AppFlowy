use crate::manager::GridUser;
use crate::services::persistence::GridDatabase;
use bytes::Bytes;
use flowy_database::kv::KV;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::GridRevision;
use flowy_revision::reset::{RevisionResettable, RevisionStructReset};
use flowy_sync::client_grid::{make_grid_rev_json_str, GridOperationsBuilder, GridRevisionPad};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::md5;

use crate::services::persistence::rev_sqlite::SQLiteGridRevisionPersistence;
use std::sync::Arc;

const V1_MIGRATION: &str = "GRID_V1_MIGRATION";

pub(crate) struct GridMigration {
    user: Arc<dyn GridUser>,
    database: Arc<dyn GridDatabase>,
}

impl GridMigration {
    pub fn new(user: Arc<dyn GridUser>, database: Arc<dyn GridDatabase>) -> Self {
        Self { user, database }
    }

    pub async fn run_v1_migration(&self, grid_id: &str) -> FlowyResult<()> {
        let user_id = self.user.user_id()?;
        let key = migration_flag_key(&user_id, V1_MIGRATION, grid_id);
        if KV::get_bool(&key) {
            return Ok(());
        }
        let _ = self.migration_grid_rev_struct(grid_id).await?;
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
        let disk_cache = SQLiteGridRevisionPersistence::new(&user_id, pool);
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
        let pad = GridRevisionPad::from_revisions(revisions)?;
        let json = pad.json_str()?;
        let bytes = GridOperationsBuilder::new().insert(&json).build().json_bytes();
        Ok(bytes)
    }

    fn default_target_rev_str(&self) -> FlowyResult<String> {
        let grid_rev = GridRevision::default();
        let json = make_grid_rev_json_str(&grid_rev)?;
        Ok(json)
    }
}
