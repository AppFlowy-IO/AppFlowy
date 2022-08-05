use crate::{
    entities::trash::{RepeatedTrashIdPB, RepeatedTrashPB, TrashIdPB},
    errors::FlowyError,
    services::TrashController,
};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn read_trash_handler(
    controller: AppData<Arc<TrashController>>,
) -> DataResult<RepeatedTrashPB, FlowyError> {
    let repeated_trash = controller.read_trash().await?;
    data_result(repeated_trash)
}

#[tracing::instrument(level = "debug", skip(identifier, controller), err)]
pub(crate) async fn putback_trash_handler(
    identifier: Data<TrashIdPB>,
    controller: AppData<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let _ = controller.putback(&identifier.id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(identifiers, controller), err)]
pub(crate) async fn delete_trash_handler(
    identifiers: Data<RepeatedTrashIdPB>,
    controller: AppData<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let _ = controller.delete(identifiers.into_inner()).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn restore_all_trash_handler(controller: AppData<Arc<TrashController>>) -> Result<(), FlowyError> {
    let _ = controller.restore_all_trash().await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn delete_all_trash_handler(controller: AppData<Arc<TrashController>>) -> Result<(), FlowyError> {
    let _ = controller.delete_all_trash().await?;
    Ok(())
}
