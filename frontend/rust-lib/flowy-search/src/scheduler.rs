use lib_infra::future::BoxResultFuture;
use lib_infra::ref_map::{RefCountHashMap, RefCountValue};

use crate::queue::TaskQueue;
use crate::runner::TaskRunner;
use crate::store::TaskStore;
use crate::{Task, TaskContent, TaskId, TaskStatus};
use anyhow::{anyhow, Error};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};

pub struct TaskScheduler {
    queue: TaskQueue,
    store: TaskStore,
    stop_tx: watch::Sender<bool>,
    handlers: RefCountHashMap<RefCountTaskHandler>,
}

impl TaskScheduler {
    pub fn new() -> Arc<RwLock<Self>> {
        let (stop_tx, stop_rx) = watch::channel(false);

        let scheduler = Self {
            queue: TaskQueue::new(),
            store: TaskStore::new(),
            stop_tx,
            handlers: RefCountHashMap::new(),
        };
        // The runner will receive the newest value after start running.
        scheduler.notify();

        let scheduler = Arc::new(RwLock::new(scheduler));
        let debounce_duration = Duration::from_millis(300);
        let runner = TaskRunner::new(scheduler.clone(), stop_rx, debounce_duration);
        tokio::spawn(runner.run());

        scheduler
    }

    pub fn register_handler<T>(&mut self, handler: Arc<T>)
    where
        T: TaskHandler,
    {
        let handler_id = handler.handler_id().to_owned();
        self.handlers.insert(handler_id, RefCountTaskHandler(handler));
    }

    pub fn unregister_handler<T: AsRef<str>>(&mut self, handler_id: T) {
        self.handlers.remove(handler_id.as_ref());
    }

    pub fn stop(&mut self) {
        let _ = self.stop_tx.send(true);
        self.queue.clear();
        self.store.clear();
    }

    pub(crate) async fn process_next_task(&mut self) -> Option<()> {
        let pending_task = self.queue.mut_head(|list| list.pop())?;
        let mut task = self.store.remove_task(&pending_task.id)?;
        let handler = self.handlers.get(&task.handler_id)?;

        let ret = task.ret.take()?;
        let content = task.content.take()?;

        task.set_status(TaskStatus::Processing);
        let _ = match handler.run(content).await {
            Ok(_) => {
                task.set_status(TaskStatus::Done);
                let _ = ret.send(task.into());
            }
            Err(e) => {
                tracing::error!("Process task failed: {:?}", e);
                task.set_status(TaskStatus::Failure);
                let _ = ret.send(task.into());
            }
        };
        self.notify();
        None
    }

    pub fn add_task(&mut self, task: Task) {
        debug_assert!(!task.is_finished());
        if task.is_finished() {
            return;
        }

        self.queue.push(&task);
        self.store.insert_task(task);
        self.notify();
    }

    pub fn next_task_id(&self) -> TaskId {
        self.store.next_task_id()
    }

    pub(crate) fn notify(&self) {
        let _ = self.stop_tx.send(false);
    }
}

pub trait TaskHandler: Send + Sync + 'static {
    fn handler_id(&self) -> &str;

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), Error>;
}

impl<T> TaskHandler for Box<T>
where
    T: TaskHandler,
{
    fn handler_id(&self) -> &str {
        (**self).handler_id()
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), Error> {
        (**self).run(content)
    }
}

impl<T> TaskHandler for Arc<T>
where
    T: TaskHandler,
{
    fn handler_id(&self) -> &str {
        (**self).handler_id()
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), Error> {
        (**self).run(content)
    }
}
#[derive(Clone)]
struct RefCountTaskHandler(Arc<dyn TaskHandler>);

impl RefCountValue for RefCountTaskHandler {
    fn did_remove(&self) {}
}

impl std::ops::Deref for RefCountTaskHandler {
    type Target = Arc<dyn TaskHandler>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
