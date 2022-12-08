use crate::disk::{RevisionDiskCache, SyncRecord};
use crate::{RevisionLoader, RevisionPersistence, RevisionPersistenceConfiguration};
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::Arc;

pub trait RevisionResettable {
    fn target_id(&self) -> &str;

    // String in json format
    fn reset_data(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes>;

    // String in json format
    fn default_target_rev_str(&self) -> FlowyResult<String>;

    fn read_record(&self) -> Option<String>;

    fn set_record(&self, record: String);
}

pub struct RevisionStructReset<T, C> {
    user_id: String,
    target: T,
    disk_cache: Arc<dyn RevisionDiskCache<C, Error = FlowyError>>,
}

impl<T, C> RevisionStructReset<T, C>
where
    T: RevisionResettable,
    C: 'static,
{
    pub fn new(user_id: &str, object: T, disk_cache: Arc<dyn RevisionDiskCache<C, Error = FlowyError>>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            target: object,
            disk_cache,
        }
    }

    pub async fn run(&self) -> FlowyResult<()> {
        match self.target.read_record() {
            None => {
                let _ = self.reset_object().await?;
                let _ = self.save_migrate_record()?;
            }
            Some(s) => {
                let mut record = MigrationObjectRecord::from_str(&s).map_err(|e| FlowyError::serde().context(e))?;
                let rev_str = self.target.default_target_rev_str()?;
                if record.len < rev_str.len() {
                    let _ = self.reset_object().await?;
                    record.len = rev_str.len();
                    self.target.set_record(record.to_string());
                }
            }
        }
        Ok(())
    }

    async fn reset_object(&self) -> FlowyResult<()> {
        let configuration = RevisionPersistenceConfiguration::new(2, false);
        let rev_persistence = Arc::new(RevisionPersistence::from_disk_cache(
            &self.user_id,
            self.target.target_id(),
            self.disk_cache.clone(),
            configuration,
        ));
        let revisions = RevisionLoader {
            object_id: self.target.target_id().to_owned(),
            user_id: self.user_id.clone(),
            cloud: None,
            rev_persistence,
        }
        .load_revisions()
        .await?;

        let bytes = self.target.reset_data(revisions)?;
        let revision = Revision::initial_revision(self.target.target_id(), bytes);
        let record = SyncRecord::new(revision);

        tracing::trace!("Reset {} revision record object", self.target.target_id());
        let _ = self
            .disk_cache
            .delete_and_insert_records(self.target.target_id(), None, vec![record]);

        Ok(())
    }

    fn save_migrate_record(&self) -> FlowyResult<()> {
        let rev_str = self.target.default_target_rev_str()?;
        let record = MigrationObjectRecord {
            object_id: self.target.target_id().to_owned(),
            len: rev_str.len(),
        };
        self.target.set_record(record.to_string());
        Ok(())
    }
}

#[derive(Serialize, Deserialize)]
struct MigrationObjectRecord {
    object_id: String,
    len: usize,
}

impl FromStr for MigrationObjectRecord {
    type Err = serde_json::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str::<MigrationObjectRecord>(s)
    }
}

impl ToString for MigrationObjectRecord {
    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_string())
    }
}
