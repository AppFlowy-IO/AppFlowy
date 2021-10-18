use crate::{
    entities::trash::{RepeatedTrash, TrashIdentifier, TrashIdentifiers},
    errors::WorkspaceError,
    services::TrashCan,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::sync::Arc;

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_trash_handler(controller: Unit<Arc<TrashCan>>) -> DataResult<RepeatedTrash, WorkspaceError> {
    let conn = controller.database.db_connection()?;
    let repeated_trash = controller.read_trash(&conn)?;
    data_result(repeated_trash)
}

#[tracing::instrument(skip(identifier, controller), err)]
pub(crate) async fn putback_trash_handler(
    identifier: Data<TrashIdentifier>,
    controller: Unit<Arc<TrashCan>>,
) -> Result<(), WorkspaceError> {
    let _ = controller.putback(&identifier.id).await?;
    Ok(())
}

#[tracing::instrument(skip(identifiers, controller), err)]
pub(crate) async fn delete_trash_handler(
    identifiers: Data<TrashIdentifiers>,
    controller: Unit<Arc<TrashCan>>,
) -> Result<(), WorkspaceError> {
    let _ = controller.delete(identifiers.into_inner()).await?;
    Ok(())
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn restore_all_handler(controller: Unit<Arc<TrashCan>>) -> Result<(), WorkspaceError> {
    let _ = controller.restore_all().await?;
    Ok(())
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn delete_all_handler(controller: Unit<Arc<TrashCan>>) -> Result<(), WorkspaceError> {
    let _ = controller.delete_all().await?;
    Ok(())
}
