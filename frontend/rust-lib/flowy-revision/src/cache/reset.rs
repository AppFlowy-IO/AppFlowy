use crate::disk::{RevisionDiskCache, RevisionRecord};
use crate::{RevisionLoader, RevisionPersistence};
use flowy_database::kv::KV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::revision::Revision;
use lib_ot::core::DeltaBuilder;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::Arc;

pub trait RevisionResettable {
    fn target_id(&self) -> &str;
    // String in json format
    fn target_reset_rev_str(&self, revisions: Vec<Revision>) -> FlowyResult<String>;

    // String in json format
    fn default_target_rev_str(&self) -> FlowyResult<String>;
}

pub struct RevisionStructReset<T> {
    user_id: String,
    target: T,
    disk_cache: Arc<dyn RevisionDiskCache<Error = FlowyError>>,
}

impl<T> RevisionStructReset<T>
where
    T: RevisionResettable,
{
    pub fn new(user_id: &str, object: T, disk_cache: Arc<dyn RevisionDiskCache<Error = FlowyError>>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            target: object,
            disk_cache,
        }
    }

    pub async fn run(&self) -> FlowyResult<()> {
        match KV::get_str(self.target.target_id()) {
            None => {
                let _ = self.reset_object().await?;
                let _ = self.save_migrate_record()?;
            }
            Some(s) => {
                let mut record = MigrationGridRecord::from_str(&s)?;
                let rev_str = self.target.default_target_rev_str()?;
                if record.len < rev_str.len() {
                    let _ = self.reset_object().await?;
                    record.len = rev_str.len();
                    KV::set_str(self.target.target_id(), record.to_string());
                }
            }
        }
        Ok(())
    }

    async fn reset_object(&self) -> FlowyResult<()> {
        let rev_persistence = Arc::new(RevisionPersistence::from_disk_cache(
            &self.user_id,
            self.target.target_id(),
            self.disk_cache.clone(),
        ));
        let (revisions, _) = RevisionLoader {
            object_id: self.target.target_id().to_owned(),
            user_id: self.user_id.clone(),
            cloud: None,
            rev_persistence,
        }
        .load()
        .await?;

        let s = self.target.target_reset_rev_str(revisions)?;
        let delta_data = DeltaBuilder::new().insert(&s).build().json_bytes();
        let revision = Revision::initial_revision(&self.user_id, self.target.target_id(), delta_data);
        let record = RevisionRecord::new(revision);

        tracing::trace!("Reset {} revision record object", self.target.target_id());
        let _ = self
            .disk_cache
            .delete_and_insert_records(self.target.target_id(), None, vec![record]);

        Ok(())
    }

    fn save_migrate_record(&self) -> FlowyResult<()> {
        let rev_str = self.target.default_target_rev_str()?;
        let record = MigrationGridRecord {
            object_id: self.target.target_id().to_owned(),
            len: rev_str.len(),
        };
        KV::set_str(self.target.target_id(), record.to_string());
        Ok(())
    }
}

#[derive(Serialize, Deserialize)]
struct MigrationGridRecord {
    object_id: String,
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
