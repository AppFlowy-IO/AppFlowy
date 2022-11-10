use crate::TaskScheduler;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tokio::time::interval;

pub struct TaskRunner {
    scheduler: Arc<RwLock<TaskScheduler>>,
    debounce_duration: Duration,
    notifier: Option<watch::Receiver<bool>>,
}

impl TaskRunner {
    pub fn new(
        scheduler: Arc<RwLock<TaskScheduler>>,
        notifier: watch::Receiver<bool>,
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

            if *notifier.borrow() {
                break;
            }

            let mut interval = interval(self.debounce_duration);
            interval.tick().await;
            let _ = self.scheduler.write().await.process_next_task().await;
        }
    }
}
