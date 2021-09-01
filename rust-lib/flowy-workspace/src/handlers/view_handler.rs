use crate::{
    entities::view::{
        CreateViewParams,
        CreateViewRequest,
        DeleteViewParams,
        DeleteViewRequest,
        QueryViewParams,
        QueryViewRequest,
        RepeatedView,
        UpdateViewParams,
        UpdateViewRequest,
        View,
    },
    errors::WorkspaceError,
    services::ViewController,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_view", skip(data, controller))]
pub(crate) async fn create_view(data: Data<CreateViewRequest>, controller: Unit<Arc<ViewController>>) -> DataResult<View, WorkspaceError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view = controller.create_view(params).await?;
    data_result(view)
}

#[tracing::instrument(name = "read_view", skip(data, controller))]
pub(crate) async fn read_view(data: Data<QueryViewRequest>, controller: Unit<Arc<ViewController>>) -> DataResult<View, WorkspaceError> {
    let params: QueryViewParams = data.into_inner().try_into()?;
    let mut view = controller.read_view(&params.view_id, params.is_trash).await?;

    if params.read_belongings {
        let views = controller.read_views_belong_to(&params.view_id).await?;
        view.belongings = RepeatedView { items: views }
    }

    data_result(view)
}

#[tracing::instrument(name = "update_view", skip(data, controller))]
pub(crate) async fn update_view(data: Data<UpdateViewRequest>, controller: Unit<Arc<ViewController>>) -> Result<(), WorkspaceError> {
    let params: UpdateViewParams = data.into_inner().try_into()?;
    let _ = controller.update_view(params).await?;

    Ok(())
}

#[tracing::instrument(name = "delete_view", skip(data, controller))]
pub(crate) async fn delete_view(data: Data<DeleteViewRequest>, controller: Unit<Arc<ViewController>>) -> Result<(), WorkspaceError> {
    let params: DeleteViewParams = data.into_inner().try_into()?;
    let _ = controller.delete_view(&params.view_id).await?;
    Ok(())
}
