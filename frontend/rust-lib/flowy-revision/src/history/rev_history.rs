use crate::history::persistence::SQLiteRevisionHistoryPersistence;
use crate::RevisionCompactor;
use async_stream::stream;
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::revision::Revision;
use futures_util::future::BoxFuture;
use futures_util::stream::StreamExt;
use futures_util::FutureExt;
use std::fmt::Debug;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::mpsc::error::SendError;
use tokio::sync::mpsc::Sender;
use tokio::sync::{mpsc, oneshot, RwLock};
use tokio::time::interval;

pub trait RevisionHistoryDiskCache: Send + Sync {
    fn save_revision(&self, revision: Revision) -> FlowyResult<()>;

    fn read_revision(&self, rev_id: i64) -> FlowyResult<Revision>;

    fn clear(&self) -> FlowyResult<()>;
}

pub struct RevisionHistory {
    stop_timer: mpsc::Sender<()>,
    config: RevisionHistoryConfig,
    revisions: Arc<RwLock<Vec<Revision>>>,
    disk_cache: Arc<dyn RevisionHistoryDiskCache>,
}

impl RevisionHistory {
    pub fn new(
        user_id: &str,
        object_id: &str,
        config: RevisionHistoryConfig,
        disk_cache: Arc<dyn RevisionHistoryDiskCache>,
        rev_compactor: Arc<dyn RevisionCompactor>,
    ) -> Self {
        let user_id = user_id.to_string();
        let object_id = object_id.to_string();
        let cloned_disk_cache = disk_cache.clone();
        let (stop_timer, stop_rx) = mpsc::channel(1);
        let (checkpoint_tx, checkpoint_rx) = mpsc::channel(1);
        let revisions = Arc::new(RwLock::new(vec![]));
        let fix_duration_checkpoint_tx = FixedDurationCheckpointSender {
            user_id,
            object_id,
            checkpoint_tx,
            disk_cache: cloned_disk_cache,
            revisions: revisions.clone(),
            rev_compactor,
            duration: config.check_duration,
        };

        tokio::spawn(CheckpointRunner::new(stop_rx, checkpoint_rx).run());
        tokio::spawn(fix_duration_checkpoint_tx.run());

        Self {
            stop_timer,
            config,
            revisions,
            disk_cache,
        }
    }

    pub async fn add_revision(&self, revision: &Revision) {
        self.revisions.write().await.push(revision.clone());
    }

    pub async fn reset_history(&self) {
        self.revisions.write().await.clear();
        match self.disk_cache.clear() {
            Ok(_) => {}
            Err(e) => tracing::error!("Clear history failed: {:?}", e),
        }
    }
}

pub struct RevisionHistoryConfig {
    check_duration: Duration,
}

impl std::default::Default for RevisionHistoryConfig {
    fn default() -> Self {
        Self {
            check_duration: Duration::from_secs(5),
        }
    }
}

struct CheckpointRunner {
    stop_rx: Option<mpsc::Receiver<()>>,
    checkpoint_rx: Option<mpsc::Receiver<HistoryCheckpoint>>,
}

impl CheckpointRunner {
    fn new(stop_rx: mpsc::Receiver<()>, checkpoint_rx: mpsc::Receiver<HistoryCheckpoint>) -> Self {
        Self {
            stop_rx: Some(stop_rx),
            checkpoint_rx: Some(checkpoint_rx),
        }
    }

    async fn run(mut self) {
        let mut stop_rx = self.stop_rx.take().expect("It should only run once");
        let mut checkpoint_rx = self.checkpoint_rx.take().expect("It should only run once");
        let stream = stream! {
            loop {
                tokio::select! {
                    result = checkpoint_rx.recv() => {
                        match result {
                            Some(checkpoint) => yield checkpoint,
                            None => {},
                        }
                    },
                    _ = stop_rx.recv() => {
                        tracing::trace!("Checkpoint runner exit");
                        break
                    },
                };
            }
        };

        stream
            .for_each(|checkpoint| async move {
                checkpoint.write().await;
            })
            .await;
    }
}

struct HistoryCheckpoint {
    user_id: String,
    object_id: String,
    revisions: Vec<Revision>,
    disk_cache: Arc<dyn RevisionHistoryDiskCache>,
    rev_compactor: Arc<dyn RevisionCompactor>,
}

impl HistoryCheckpoint {
    async fn write(self) {
        if self.revisions.is_empty() {
            return;
        }

        let result = || {
            let revision = self
                .rev_compactor
                .compact(&self.user_id, &self.object_id, self.revisions)?;
            let _ = self.disk_cache.save_revision(revision)?;
            Ok::<(), FlowyError>(())
        };

        match result() {
            Ok(_) => {}
            Err(e) => tracing::error!("Write history checkout failed: {:?}", e),
        }
    }
}

struct FixedDurationCheckpointSender {
    user_id: String,
    object_id: String,
    checkpoint_tx: mpsc::Sender<HistoryCheckpoint>,
    disk_cache: Arc<dyn RevisionHistoryDiskCache>,
    revisions: Arc<RwLock<Vec<Revision>>>,
    rev_compactor: Arc<dyn RevisionCompactor>,
    duration: Duration,
}

impl FixedDurationCheckpointSender {
    fn run(self) -> BoxFuture<'static, ()> {
        async move {
            let mut interval = interval(self.duration);
            let checkpoint_revisions: Vec<Revision> = revisions.write().await.drain(..).collect();
            let checkpoint = HistoryCheckpoint {
                user_id: self.user_id.clone(),
                object_id: self.object_id.clone(),
                revisions: checkpoint_revisions,
                disk_cache: self.disk_cache.clone(),
                rev_compactor: self.rev_compactor.clone(),
            };
            match checkpoint_tx.send(checkpoint).await {
                Ok(_) => {
                    interval.tick().await;
                    self.run();
                }
                Err(_) => {}
            }
        }
        .boxed()
    }
}
