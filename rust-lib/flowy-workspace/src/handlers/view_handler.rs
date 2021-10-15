use crate::{
    entities::view::{
        CreateViewParams,
        CreateViewRequest,
        DeleteViewParams,
        DeleteViewRequest,
        OpenViewRequest,
        QueryViewParams,
        QueryViewRequest,
        UpdateViewParams,
        UpdateViewRequest,
        View,
    },
    errors::WorkspaceError,
    services::ViewController,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use flowy_document::entities::doc::{DocDelta, DocIdentifier};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_view_handler(
    data: Data<CreateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, WorkspaceError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view = controller.create_view(params).await?;
    data_result(view)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn read_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, WorkspaceError> {
    let params: QueryViewParams = data.into_inner().try_into()?;
    let mut view = controller.read_view(params.clone()).await?;

    if params.read_belongings {
        view.belongings = controller.read_views_belong_to(&params.view_id).await?;
    }

    data_result(view)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn update_view_handler(
    data: Data<UpdateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), WorkspaceError> {
    let params: UpdateViewParams = data.into_inner().try_into()?;
    let _ = controller.update_view(params).await?;

    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn apply_doc_delta_handler(
    data: Data<DocDelta>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocDelta, WorkspaceError> {
    // let params: DocDelta = data.into_inner().try_into()?;
    let doc = controller.apply_doc_delta(data.into_inner()).await?;
    data_result(doc)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn delete_view_handler(
    data: Data<DeleteViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), WorkspaceError> {
    let params: DeleteViewParams = data.into_inner().try_into()?;
    let _ = controller.delete_view(params).await?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn open_view_handler(
    data: Data<OpenViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocDelta, WorkspaceError> {
    let params: DocIdentifier = data.into_inner().try_into()?;
    let doc = controller.open_view(params).await?;
    data_result(doc)
}
