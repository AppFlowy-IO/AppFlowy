use crate::TaskScheduler;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tokio::time::interval;

pub struct TaskRunner {
    scheduler: Arc<RwLock<TaskScheduler>>,
    debounce_duration: Duration,
    stop_rx: Option<watch::Receiver<bool>>,
}

impl TaskRunner {
    pub fn new(
        scheduler: Arc<RwLock<TaskScheduler>>,
        stop_rx: watch::Receiver<bool>,
        debounce_duration: Duration,
    ) -> Self {
        Self {
            scheduler,
            debounce_duration,
            stop_rx: Some(stop_rx),
        }
    }

    pub async fn run(mut self) {
        let mut stop_rx = self
            .stop_rx
            .take()
            .expect("The GridTaskRunner's notifier should only take once");

        loop {
            if stop_rx.changed().await.is_err() {
                // The runner will be stopped if the corresponding Sender drop.
                break;
            }

            if *stop_rx.borrow() {
                break;
            }

            let mut interval = interval(self.debounce_duration);
            interval.tick().await;
            let _ = self.scheduler.write().await.process_next_task().await;
        }
    }
}
