use crate::{RevisionCompactor, RevisionHistory};
use async_stream::stream;

use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::revision::Revision;
use futures_util::future::BoxFuture;
use futures_util::stream::StreamExt;
use futures_util::FutureExt;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{mpsc, RwLock};
use tokio::time::interval;

pub trait RevisionHistoryDiskCache: Send + Sync {
    fn write_history(&self, revision: Revision) -> FlowyResult<()>;

    fn read_histories(&self) -> FlowyResult<Vec<RevisionHistory>>;
}

pub struct RevisionHistoryManager {
    user_id: String,
    stop_tx: mpsc::Sender<()>,
    config: RevisionHistoryConfig,
    revisions: Arc<RwLock<Vec<Revision>>>,
    disk_cache: Arc<dyn RevisionHistoryDiskCache>,
}

impl RevisionHistoryManager {
    pub fn new(
        user_id: &str,
        object_id: &str,
        config: RevisionHistoryConfig,
        disk_cache: Arc<dyn RevisionHistoryDiskCache>,
        rev_compactor: Arc<dyn RevisionCompactor>,
    ) -> Self {
        let revisions = Arc::new(RwLock::new(vec![]));
        let stop_tx =
            spawn_history_checkpoint_runner(user_id, object_id, &disk_cache, &revisions, rev_compactor, &config);
        let user_id = user_id.to_owned();
        Self {
            user_id,
            stop_tx,
            config,
            revisions,
            disk_cache,
        }
    }

    pub async fn add_revision(&self, revision: &Revision) {
        self.revisions.write().await.push(revision.clone());
    }

    pub async fn read_revision_histories(&self) -> FlowyResult<Vec<RevisionHistory>> {
        self.disk_cache.read_histories()
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

fn spawn_history_checkpoint_runner(
    user_id: &str,
    object_id: &str,
    disk_cache: &Arc<dyn RevisionHistoryDiskCache>,
    revisions: &Arc<RwLock<Vec<Revision>>>,
    rev_compactor: Arc<dyn RevisionCompactor>,
    config: &RevisionHistoryConfig,
) -> mpsc::Sender<()> {
    let user_id = user_id.to_string();
    let object_id = object_id.to_string();
    let disk_cache = disk_cache.clone();
    let revisions = revisions.clone();

    let (checkpoint_tx, checkpoint_rx) = mpsc::channel(1);
    let (stop_tx, stop_rx) = mpsc::channel(1);
    let checkpoint_sender = FixedDurationCheckpointSender {
        user_id,
        object_id,
        checkpoint_tx,
        disk_cache,
        revisions,
        rev_compactor,
        duration: config.check_duration,
    };
    tokio::spawn(HistoryCheckpointRunner::new(stop_rx, checkpoint_rx).run());
    tokio::spawn(checkpoint_sender.run());
    stop_tx
}

struct HistoryCheckpointRunner {
    stop_rx: Option<mpsc::Receiver<()>>,
    checkpoint_rx: Option<mpsc::Receiver<HistoryCheckpoint>>,
}

impl HistoryCheckpointRunner {
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
            let _ = self.disk_cache.write_history(revision)?;
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
            let checkpoint_revisions: Vec<Revision> = self.revisions.write().await.drain(..).collect();
            let checkpoint = HistoryCheckpoint {
                user_id: self.user_id.clone(),
                object_id: self.object_id.clone(),
                revisions: checkpoint_revisions,
                disk_cache: self.disk_cache.clone(),
                rev_compactor: self.rev_compactor.clone(),
            };
            match self.checkpoint_tx.send(checkpoint).await {
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
