use crate::{
    entities::workspace::{CreateWorkspaceParams, CreateWorkspaceRequest, WorkspaceDetail},
    errors::WorkspaceError,
    services::{save_workspace, WorkspaceController},
};
use flowy_dispatch::prelude::{response_ok, Data, EventResponse, ModuleData, ResponseResult};
use std::{convert::TryInto, pin::Pin, sync::Arc};

pub async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: ModuleData<Arc<WorkspaceController>>,
) -> ResponseResult<WorkspaceDetail, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = save_workspace(controller, params).await?;
    response_ok(detail)
}
