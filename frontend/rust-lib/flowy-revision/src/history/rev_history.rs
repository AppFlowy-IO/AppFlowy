use crate::history::persistence::SQLiteRevisionHistoryPersistence;
use flowy_error::FlowyError;
use flowy_sync::entities::revision::Revision;
use std::fmt::Debug;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait RevisionHistoryDiskCache: Send + Sync {
    type Error: Debug;

    fn save_revision(&self, revision: Revision) -> Result<(), Self::Error>;
}

pub struct RevisionHistory {
    config: RevisionHistoryConfig,
    checkpoint: Arc<RwLock<HistoryCheckpoint>>,
    disk_cache: Arc<dyn RevisionHistoryDiskCache<Error = FlowyError>>,
}

impl RevisionHistory {
    pub fn new(config: RevisionHistoryConfig) -> Self {
        let disk_cache = Arc::new(SQLiteRevisionHistoryPersistence::new());
        let cloned_disk_cache = disk_cache.clone();
        let checkpoint = HistoryCheckpoint::from_config(&config, move |revision| {
            let _ = cloned_disk_cache.save_revision(revision);
        });
        let checkpoint = Arc::new(RwLock::new(checkpoint));

        Self {
            config,
            checkpoint,
            disk_cache,
        }
    }

    pub async fn save_revision(&self, revision: &Revision) {
        self.checkpoint.write().await.add_revision(revision);
    }
}

pub struct RevisionHistoryConfig {
    check_when_close: bool,
    check_interval: i64,
}

impl std::default::Default for RevisionHistoryConfig {
    fn default() -> Self {
        Self {
            check_when_close: true,
            check_interval: 19,
        }
    }
}

struct HistoryCheckpoint {
    interval: i64,
    revisions: Vec<Revision>,
    on_check: Box<dyn Fn(Revision) + Send + Sync + 'static>,
}

impl HistoryCheckpoint {
    fn from_config<F>(config: &RevisionHistoryConfig, on_check: F) -> Self
    where
        F: Fn(Revision) + Send + Sync + 'static,
    {
        Self {
            interval: config.check_interval,
            revisions: vec![],
            on_check: Box::new(on_check),
        }
    }

    fn check(&mut self) -> Revision {
        todo!()
    }

    fn add_revision(&mut self, revision: &Revision) {}
}
