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
    errors::FlowyError,
    services::{TrashController, ViewController},
};
use flowy_collaboration::entities::doc::DocumentDelta;
use flowy_core_data_model::entities::share::{ExportData, ExportParams, ExportRequest};
use lib_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_view_handler(
    data: Data<CreateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, FlowyError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view = controller.create_view_from_params(params).await?;
    data_result(view)
}

pub(crate) async fn read_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<View, FlowyError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let mut view = controller.read_view(params.clone()).await?;
    view.belongings = controller.read_views_belong_to(&params.view_id).await?;

    data_result(view)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn update_view_handler(
    data: Data<UpdateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let params: UpdateViewParams = data.into_inner().try_into()?;
    let _ = controller.update_view(params).await?;

    Ok(())
}

pub(crate) async fn apply_doc_delta_handler(
    data: Data<DocumentDelta>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocumentDelta, FlowyError> {
    // let params: DocumentDelta = data.into_inner().try_into()?;
    let doc = controller.apply_doc_delta(data.into_inner()).await?;
    data_result(doc)
}

pub(crate) async fn delete_view_handler(
    data: Data<QueryViewRequest>,
    view_controller: Unit<Arc<ViewController>>,
    trash_controller: Unit<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let params: ViewIdentifiers = data.into_inner().try_into()?;
    for view_id in &params.view_ids {
        let _ = view_controller.delete_view(view_id.into()).await;
    }

    let trash = view_controller
        .read_view_tables(params.view_ids)?
        .into_iter()
        .map(|view_table| view_table.into())
        .collect::<Vec<Trash>>();

    let _ = trash_controller.add(trash).await?;
    Ok(())
}

pub(crate) async fn open_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<DocumentDelta, FlowyError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let doc = controller.open_view(params.into()).await?;
    data_result(doc)
}

pub(crate) async fn close_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let _ = controller.close_view(params.into()).await?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn duplicate_view_handler(
    data: Data<QueryViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let params: ViewIdentifier = data.into_inner().try_into()?;
    let _ = controller.duplicate_view(params.into()).await?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn export_handler(
    data: Data<ExportRequest>,
    controller: Unit<Arc<ViewController>>,
) -> DataResult<ExportData, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let data = controller.export_doc(params).await?;
    data_result(data)
}
