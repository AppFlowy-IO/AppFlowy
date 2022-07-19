use crate::services::tasks::queue::{GridTaskQueue, TaskHandlerId};
use crate::services::tasks::runner::GridTaskRunner;
use crate::services::tasks::store::GridTaskStore;
use crate::services::tasks::task::Task;

use crate::services::tasks::{TaskContent, TaskId, TaskStatus};
use flowy_error::FlowyError;
use lib_infra::future::BoxResultFuture;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{watch, RwLock};

pub(crate) trait GridTaskHandler: Send + Sync + 'static {
    fn handler_id(&self) -> &str;

    fn process_content(&self, content: TaskContent) -> BoxResultFuture<(), FlowyError>;
}

pub struct GridTaskScheduler {
    queue: GridTaskQueue,
    store: GridTaskStore,
    notifier: watch::Sender<bool>,
    handlers: HashMap<TaskHandlerId, Arc<dyn GridTaskHandler>>,
}

impl GridTaskScheduler {
    pub(crate) fn new() -> Arc<RwLock<Self>> {
        let (notifier, rx) = watch::channel(false);

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

    pub(crate) fn register_handler<T>(&mut self, handler: Arc<T>)
    where
        T: GridTaskHandler,
    {
        let handler_id = handler.handler_id().to_owned();
        self.handlers.insert(handler_id, handler);
    }

    pub(crate) fn unregister_handler<T: AsRef<str>>(&mut self, handler_id: T) {
        let _ = self.handlers.remove(handler_id.as_ref());
    }

    #[allow(dead_code)]
    pub(crate) fn stop(&mut self) {
        let _ = self.notifier.send(true);
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
        let _ = match handler.process_content(content).await {
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

    pub(crate) fn add_task(&mut self, task: Task) {
        assert!(!task.is_finished());
        self.queue.push(&task);
        self.store.insert_task(task);
        self.notify();
    }

    pub(crate) fn next_task_id(&self) -> TaskId {
        self.store.next_task_id()
    }

    pub(crate) fn notify(&self) {
        let _ = self.notifier.send(false);
    }
}

#[cfg(test)]
mod tests {
    use crate::services::grid_editor_task::GridServiceTaskScheduler;
    use crate::services::tasks::{GridTaskHandler, GridTaskScheduler, Task, TaskContent, TaskStatus};
    use flowy_error::FlowyError;
    use lib_infra::future::BoxResultFuture;
    use std::sync::Arc;
    use std::time::Duration;
    use tokio::time::interval;

    #[tokio::test]
    async fn task_scheduler_snapshot_task_test() {
        let scheduler = GridTaskScheduler::new();
        scheduler
            .write()
            .await
            .register_handler(Arc::new(MockGridTaskHandler()));

        let task_id = scheduler.gen_task_id().await;
        let mut task = Task::new("1", task_id, TaskContent::Snapshot);
        let rx = task.rx.take().unwrap();
        scheduler.write().await.add_task(task);
        assert_eq!(rx.await.unwrap().status, TaskStatus::Done);
    }

    #[tokio::test]
    async fn task_scheduler_snapshot_task_cancel_test() {
        let scheduler = GridTaskScheduler::new();
        scheduler
            .write()
            .await
            .register_handler(Arc::new(MockGridTaskHandler()));

        let task_id = scheduler.gen_task_id().await;
        let mut task = Task::new("1", task_id, TaskContent::Snapshot);
        let rx = task.rx.take().unwrap();
        scheduler.write().await.add_task(task);
        scheduler.write().await.stop();

        assert_eq!(rx.await.unwrap().status, TaskStatus::Cancel);
    }

    #[tokio::test]
    async fn task_scheduler_multi_task_test() {
        let scheduler = GridTaskScheduler::new();
        scheduler
            .write()
            .await
            .register_handler(Arc::new(MockGridTaskHandler()));

        let task_id = scheduler.gen_task_id().await;
        let mut task_1 = Task::new("1", task_id, TaskContent::Snapshot);
        let rx_1 = task_1.rx.take().unwrap();

        let task_id = scheduler.gen_task_id().await;
        let mut task_2 = Task::new("1", task_id, TaskContent::Snapshot);
        let rx_2 = task_2.rx.take().unwrap();

        scheduler.write().await.add_task(task_1);
        scheduler.write().await.add_task(task_2);

        assert_eq!(rx_1.await.unwrap().status, TaskStatus::Done);
        assert_eq!(rx_2.await.unwrap().status, TaskStatus::Done);
    }
    struct MockGridTaskHandler();
    impl GridTaskHandler for MockGridTaskHandler {
        fn handler_id(&self) -> &str {
            "1"
        }

        fn process_content(&self, _content: TaskContent) -> BoxResultFuture<(), FlowyError> {
            Box::pin(async move {
                let mut interval = interval(Duration::from_secs(1));
                interval.tick().await;
                interval.tick().await;
                Ok(())
            })
        }
    }
}
