use crate::services::grid_editor::GridRevisionEditor;
use crate::services::tasks::{GridTaskHandler, Task, TaskContent, TaskHandlerId};
use flowy_error::FlowyError;

use lib_infra::future::BoxResultFuture;

impl GridTaskHandler for GridRevisionEditor {
    fn handler_id(&self) -> &TaskHandlerId {
        &self.grid_id
    }

    fn process_task(&self, task: Task) -> BoxResultFuture<(), FlowyError> {
        Box::pin(async move {
            match &task.content {
                TaskContent::Snapshot { .. } => {}
                TaskContent::Filter => self.filter_service.process_task(task).await?,
            }
            Ok(())
        })
    }
}
