use crate::services::tasks::scheduler::GridTaskScheduler;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tokio::time::interval;

pub struct GridTaskRunner {
    scheduler: Arc<RwLock<GridTaskScheduler>>,
    debounce_duration: Duration,
    notifier: Option<watch::Receiver<()>>,
}

impl GridTaskRunner {
    pub fn new(
        scheduler: Arc<RwLock<GridTaskScheduler>>,
        notifier: watch::Receiver<()>,
        debounce_duration: Duration,
    ) -> Self {
        Self {
            scheduler,
            debounce_duration,
            notifier: Some(notifier),
        }
    }

    pub async fn run(mut self) {
        let mut notifier = self
            .notifier
            .take()
            .expect("The GridTaskRunner's notifier should only take once");

        loop {
            if notifier.changed().await.is_err() {
                // The runner will be stopped if the corresponding Sender drop.
                break;
            }
            let mut interval = interval(self.debounce_duration);
            interval.tick().await;

            if let Err(e) = self.scheduler.write().await.process_next_task().await {
                tracing::error!("{:?}", e);
            }
        }
    }
}
