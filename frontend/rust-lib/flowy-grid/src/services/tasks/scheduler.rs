use crate::services::tasks::queue::{GridTaskQueue, TaskHandlerId};
use crate::services::tasks::runner::GridTaskRunner;
use crate::services::tasks::store::GridTaskStore;
use crate::services::tasks::task::Task;

use crate::services::tasks::TaskId;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::BoxResultFuture;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};

pub trait GridTaskHandler: Send + Sync + 'static {
    fn handler_id(&self) -> &TaskHandlerId;

    fn process_task(&self, task: Task) -> BoxResultFuture<(), FlowyError>;
}

pub struct GridTaskScheduler {
    queue: GridTaskQueue,
    store: GridTaskStore,
    notifier: watch::Sender<()>,
    handlers: HashMap<TaskHandlerId, Arc<dyn GridTaskHandler>>,
}

impl GridTaskScheduler {
    pub fn new() -> Arc<RwLock<Self>> {
        let (notifier, rx) = watch::channel(());

        let scheduler = Self {
            queue: GridTaskQueue::new(),
            store: GridTaskStore::new(),
            notifier,
            handlers: HashMap::new(),
        };
        // The runner will receive the newest value after start running.
        scheduler.notify();

        let scheduler = Arc::new(RwLock::new(scheduler));
        let debounce_duration = Duration::from_millis(300);
        let runner = GridTaskRunner::new(scheduler.clone(), rx, debounce_duration);
        tokio::spawn(runner.run());

        scheduler
    }

    pub fn register_handler<T>(&mut self, handler: Arc<T>)
    where
        T: GridTaskHandler,
    {
        let handler_id = handler.handler_id().to_owned();
        self.handlers.insert(handler_id, handler);
    }

    pub fn unregister_handler<T: AsRef<str>>(&mut self, handler_id: T) {
        let _ = self.handlers.remove(handler_id.as_ref());
    }

    pub async fn process_next_task(&mut self) -> FlowyResult<()> {
        let mut get_next_task = || {
            let pending_task = self.queue.mut_head(|list| list.pop())?;
            let task = self.store.remove_task(&pending_task.id)?;
            Some(task)
        };

        if let Some(task) = get_next_task() {
            match self.handlers.get(&task.hid) {
                None => {}
                Some(handler) => {
                    let _ = handler.process_task(task).await;
                }
            }
        }
        Ok(())
    }

    pub fn register_task(&mut self, task: Task) {
        assert!(!task.is_finished());
        self.queue.push(&task);
        self.store.insert_task(task);
        self.notify();
    }

    pub fn next_task_id(&self) -> TaskId {
        self.store.next_task_id()
    }

    pub fn notify(&self) {
        let _ = self.notifier.send(());
    }
}
