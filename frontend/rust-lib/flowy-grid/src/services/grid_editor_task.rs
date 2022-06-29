use crate::manager::GridTaskSchedulerRwLock;
use crate::services::grid_editor::GridRevisionEditor;
use crate::services::tasks::{GridTaskHandler, Task, TaskContent, TaskHandlerId, TaskId};
use flowy_error::FlowyError;
use futures::future::BoxFuture;
use lib_infra::future::BoxResultFuture;

pub trait GridServiceTaskScheduler: Send + Sync + 'static {
    fn gen_task_id(&self) -> BoxFuture<TaskId>;
    fn register_task(&self, task: Task) -> BoxFuture<()>;
}

impl GridTaskHandler for GridRevisionEditor {
    fn handler_id(&self) -> &TaskHandlerId {
        &self.grid_id
    }

    fn process_task(&self, task: Task) -> BoxResultFuture<(), FlowyError> {
        Box::pin(async move {
            match &task.content {
                TaskContent::Snapshot { .. } => {}
                TaskContent::Filter { .. } => self.filter_service.process_task(task).await?,
            }
            Ok(())
        })
    }
}

impl GridServiceTaskScheduler for GridTaskSchedulerRwLock {
    fn gen_task_id(&self) -> BoxFuture<TaskId> {
        let this = self.clone();
        Box::pin(async move { this.read().await.next_task_id() })
    }

    fn register_task(&self, task: Task) -> BoxFuture<()> {
        let this = self.clone();
        Box::pin(async move {
            this.write().await.register_task(task);
        })
    }
}
