use crate::services::grid_editor::GridRevisionEditor;
use crate::services::tasks::{GridTaskHandler, Task, TaskContent};
use flowy_error::FlowyError;
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;

impl GridTaskHandler for Arc<GridRevisionEditor> {
    fn handler_id(&self) -> &str {
        &self.grid_id
    }

    fn process_task(&self, task: Task) -> BoxResultFuture<(), FlowyError> {
        Box::pin(async move {
            match task.content {
                TaskContent::Snapshot { .. } => {}
                TaskContent::Filter => {}
            }
            Ok(())
        })
    }
}
