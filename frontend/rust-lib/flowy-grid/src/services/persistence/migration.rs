use crate::manager::GridUser;

use crate::services::persistence::GridDatabase;
use flowy_database::kv::KV;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::GridRevision;
use flowy_revision::disk::{RevisionRecord, SQLiteGridRevisionPersistence};
use flowy_revision::{mk_grid_block_revision_disk_cache, RevisionLoader, RevisionPersistence};
use flowy_sync::client_grid::{make_grid_rev_json_str, GridRevisionPad};
use flowy_sync::entities::revision::Revision;

use lib_ot::core::PlainTextDeltaBuilder;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::Arc;

pub(crate) struct GridMigration {
    user: Arc<dyn GridUser>,
    database: Arc<dyn GridDatabase>,
}

impl GridMigration {
    pub fn new(user: Arc<dyn GridUser>, database: Arc<dyn GridDatabase>) -> Self {
        Self { user, database }
    }

    pub async fn migration_grid_if_need(&self, grid_id: &str) -> FlowyResult<()> {
        match KV::get_str(grid_id) {
            None => {
                let _ = self.reset_grid_rev(grid_id).await?;
                let _ = self.save_migrate_record(grid_id)?;
            }
            Some(s) => {
                let mut record = MigrationGridRecord::from_str(&s)?;
                let empty_json = self.empty_grid_rev_json()?;
                if record.len < empty_json.len() {
                    let _ = self.reset_grid_rev(grid_id).await?;
                    record.len = empty_json.len();
                    KV::set_str(grid_id, record.to_string());
                }
            }
        }
        Ok(())
    }

    async fn reset_grid_rev(&self, grid_id: &str) -> FlowyResult<()> {
        let user_id = self.user.user_id()?;
        let pool = self.database.db_pool()?;
        let grid_rev_pad = self.get_grid_revision_pad(grid_id).await?;
        let json = grid_rev_pad.json_str()?;
        let delta_data = PlainTextDeltaBuilder::new().insert(&json).build().to_delta_bytes();
        let revision = Revision::initial_revision(&user_id, grid_id, delta_data);
        let record = RevisionRecord::new(revision);
        //
        let disk_cache = mk_grid_block_revision_disk_cache(&user_id, pool);
        let _ = disk_cache.delete_and_insert_records(grid_id, None, vec![record]);
        Ok(())
    }

    fn save_migrate_record(&self, grid_id: &str) -> FlowyResult<()> {
        let empty_json_str = self.empty_grid_rev_json()?;
        let record = MigrationGridRecord {
            grid_id: grid_id.to_owned(),
            len: empty_json_str.len(),
        };
        KV::set_str(grid_id, record.to_string());
        Ok(())
    }

    fn empty_grid_rev_json(&self) -> FlowyResult<String> {
        let empty_grid_rev = GridRevision::default();
        let empty_json = make_grid_rev_json_str(&empty_grid_rev)?;
        Ok(empty_json)
    }

    async fn get_grid_revision_pad(&self, grid_id: &str) -> FlowyResult<GridRevisionPad> {
        let pool = self.database.db_pool()?;
        let user_id = self.user.user_id()?;
        let disk_cache = SQLiteGridRevisionPersistence::new(&user_id, pool);
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, grid_id, disk_cache));
        let (revisions, _) = RevisionLoader {
            object_id: grid_id.to_owned(),
            user_id,
            cloud: None,
            rev_persistence,
        }
        .load()
        .await?;

        let pad = GridRevisionPad::from_revisions(revisions)?;
        Ok(pad)
    }
}

#[derive(Serialize, Deserialize)]
struct MigrationGridRecord {
    grid_id: String,
    len: usize,
}

impl FromStr for MigrationGridRecord {
    type Err = serde_json::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str::<MigrationGridRecord>(s)
    }
}

impl ToString for MigrationGridRecord {
    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_string())
    }
}
