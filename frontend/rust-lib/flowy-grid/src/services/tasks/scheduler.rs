use crate::services::tasks::queue::GridTaskQueue;
use crate::services::tasks::runner::GridTaskRunner;
use crate::services::tasks::store::GridTaskStore;
use crate::services::tasks::task::Task;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};

pub trait GridTaskHandler: Send + Sync + 'static {
    fn handler_id(&self) -> &str;

    fn process_task(&self, task: Task) -> BoxResultFuture<(), FlowyError>;
}

pub struct GridTaskScheduler {
    queue: GridTaskQueue,
    store: GridTaskStore,
    notifier: watch::Sender<()>,
    handlers: Vec<Arc<dyn GridTaskHandler>>,
}

impl GridTaskScheduler {
    pub fn new() -> Arc<RwLock<Self>> {
        let (notifier, rx) = watch::channel(());

        let scheduler = Self {
            queue: GridTaskQueue::new(),
            store: GridTaskStore::new(),
            notifier,
            handlers: vec![],
        };
        // The runner will receive the newest value after start running.
        scheduler.notify();

        let scheduler = Arc::new(RwLock::new(scheduler));
        let debounce_duration = Duration::from_millis(300);
        let runner = GridTaskRunner::new(scheduler.clone(), rx, debounce_duration);
        tokio::spawn(runner.run());

        scheduler
    }

    pub fn register_handler<T>(&mut self, handler: T)
    where
        T: GridTaskHandler,
    {
        // todo!()
    }

    pub fn process_next_task(&mut self) -> FlowyResult<()> {
        Ok(())
    }

    pub fn register_task(&self, task: Task) {
        assert!(!task.is_finished());
    }

    pub fn notify(&self) {
        let _ = self.notifier.send(());
    }
}
