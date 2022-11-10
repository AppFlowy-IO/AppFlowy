use lib_infra::future::BoxResultFuture;
use lib_infra::ref_map::{RefCountHashMap, RefCountValue};

use crate::queue::TaskQueue;
use crate::runner::TaskRunner;
use crate::store::TaskStore;
use crate::{Task, TaskContent, TaskId, TaskState};
use anyhow::{anyhow, Error};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tokio::time::error::Elapsed;

pub struct TaskScheduler {
    queue: TaskQueue,
    store: TaskStore,
    notifier: watch::Sender<bool>,
    timeout: Duration,
    handlers: RefCountHashMap<RefCountTaskHandler>,
}

impl TaskScheduler {
    pub fn new(timeout: Duration) -> Arc<RwLock<Self>> {
        let (notifier, stop_rx) = watch::channel(false);

        let scheduler = Self {
            queue: TaskQueue::new(),
            store: TaskStore::new(),
            notifier,
            timeout,
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
        let _ = self.notifier.send(true);
        self.queue.clear();
        self.store.clear();
    }

    pub(crate) async fn process_next_task(&mut self) -> Option<()> {
        let pending_task = self.queue.mut_head(|list| list.pop())?;
        let mut task = self.store.remove_task(&pending_task.id)?;
        let ret = task.ret.take()?;

        // Do not execute the task if the task was cancelled.
        if task.state().is_cancel() {
            let _ = ret.send(task.into());
            self.notify();
            return None;
        }

        let content = task.content.take()?;
        if let Some(handler) = self.handlers.get(&task.handler_id) {
            task.set_state(TaskState::Processing);
            match tokio::time::timeout(self.timeout, handler.run(content)).await {
                Ok(result) => match result {
                    Ok(_) => task.set_state(TaskState::Done),
                    Err(e) => {
                        tracing::error!("Process task failed: {:?}", e);
                        task.set_state(TaskState::Failure);
                    }
                },
                Err(e) => {
                    tracing::error!("Process task timeout: {:?}", e);
                    task.set_state(TaskState::Timeout);
                }
            }
        } else {
            tracing::warn!("Can not find the handler:{}", task.handler_id);
            task.set_state(TaskState::Failure);
        }
        let _ = ret.send(task.into());
        self.notify();
        None
    }

    pub fn add_task(&mut self, task: Task) {
        debug_assert!(!task.state().is_done());
        if task.state().is_done() {
            return;
        }

        self.queue.push(&task);
        self.store.insert_task(task);
        self.notify();
    }

    pub fn read_task(&self, task_id: &TaskId) -> Option<&Task> {
        self.store.read_task(task_id)
    }

    pub fn cancel_task(&mut self, task_id: TaskId) {
        if let Some(mut task) = self.store.mut_task(&task_id) {
            task.set_state(TaskState::Cancel);
        }
    }

    pub fn next_task_id(&self) -> TaskId {
        self.store.next_task_id()
    }

    pub(crate) fn notify(&self) {
        let _ = self.notifier.send(false);
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
