use crate::manager::GridTaskSchedulerRwLock;
use crate::services::grid_editor::GridRevisionEditor;
use crate::services::tasks::{GridTaskHandler, Task, TaskContent, TaskId};
use flowy_error::FlowyError;
use futures::future::BoxFuture;
use lib_infra::future::BoxResultFuture;

pub(crate) trait GridServiceTaskScheduler: Send + Sync + 'static {
    fn gen_task_id(&self) -> BoxFuture<TaskId>;
    fn add_task(&self, task: Task) -> BoxFuture<()>;
}

impl GridTaskHandler for GridRevisionEditor {
    fn handler_id(&self) -> &str {
        &self.grid_id
    }

    fn process_content(&self, content: TaskContent) -> BoxResultFuture<(), FlowyError> {
        Box::pin(async move {
            match content {
                TaskContent::Snapshot => {}
                TaskContent::Group => {}
                TaskContent::Filter(context) => self.filter_service.process(context).await?,
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

    fn add_task(&self, task: Task) -> BoxFuture<()> {
        let this = self.clone();
        Box::pin(async move {
            this.write().await.add_task(task);
        })
    }
}
