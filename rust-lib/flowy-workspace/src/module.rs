use flowy_dispatch::prelude::*;

use crate::{event::WorkspaceEvent, handlers::create_workspace, services::WorkspaceController};
use std::sync::Arc;

pub fn create(controller: Arc<WorkspaceController>) -> Module {
    Module::new()
        .name("Flowy-Workspace")
        .data(controller)
        .event(WorkspaceEvent::CreateWorkspace, create_workspace)
}
