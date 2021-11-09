use crate::{
    entities::{
        trash::Trash,
        view::{
            CreateViewParams,
            CreateViewRequest,
            QueryViewRequest,
            UpdateViewParams,
            UpdateViewRequest,
            View,
            ViewIdentifier,
            ViewIdentifiers,
        },
    },
    errors::WorkspaceError,
    services::{TrashCan, ViewController},
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use flowy_document::entities::doc::DocDelta;
use flowy_workspace_infra::entities::share::{ExportParams, ExportRequest};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_view_handler(
    data: Data<CreateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, WorkspaceError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view = controller.create_view_from_params(params).await?;
    data_result(view)
}

pub(crate) async fn read_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, WorkspaceError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let mut view = controller.read_view(params.clone()).await?;
    view.belongings = controller.read_views_belong_to(&params.view_id).await?;

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

pub(crate) async fn apply_doc_delta_handler(
    data: Data<DocDelta>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocDelta, WorkspaceError> {
    // let params: DocDelta = data.into_inner().try_into()?;
    let doc = controller.apply_doc_delta(data.into_inner()).await?;
    data_result(doc)
}

pub(crate) async fn delete_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
    trash_can: Unit<Arc<TrashCan>>,
) -> Result<(), WorkspaceError> {
    let params: ViewIdentifiers = data.into_inner().try_into()?;
    for view_id in &params.view_ids {
        let _ = controller.close_view(view_id.into()).await;
    }

    let trash = controller
        .read_view_tables(params.view_ids)?
        .into_iter()
        .map(|view_table| view_table.into())
        .collect::<Vec<Trash>>();

    let _ = trash_can.add(trash).await?;
    Ok(())
}

pub(crate) async fn open_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocDelta, WorkspaceError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let doc = controller.open_view(params.into()).await?;
    data_result(doc)
}

pub(crate) async fn close_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), WorkspaceError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let _ = controller.close_view(params.into()).await?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn duplicate_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), WorkspaceError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let _ = controller.duplicate_view(params.into()).await?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn export_handler(
    data: Data<ExportRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), WorkspaceError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let _ = controller.export_doc(params.into()).await?;
    Ok(())
}
