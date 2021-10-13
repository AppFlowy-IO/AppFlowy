use crate::{
    entities::{
        trash::{RepeatedTrash, TrashIdentifier},
        view::RepeatedView,
    },
    errors::WorkspaceError,
    services::TrashCan,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_trash_handler(controller: Unit<Arc<TrashCan>>) -> DataResult<RepeatedTrash, WorkspaceError> {
    let repeated_trash = controller.read_trash()?;
    data_result(repeated_trash)
}

#[tracing::instrument(skip(identifier, controller), err)]
pub(crate) async fn putback_trash_handler(
    identifier: Data<TrashIdentifier>,
    controller: Unit<Arc<TrashCan>>,
) -> Result<(), WorkspaceError> {
    let _ = controller.putback(&identifier.id)?;
    Ok(())
}

#[tracing::instrument(skip(identifier, controller), err)]
pub(crate) async fn delete_trash_handler(
    identifier: Data<TrashIdentifier>,
    controller: Unit<Arc<TrashCan>>,
) -> Result<(), WorkspaceError> {
    let _ = controller.delete_trash(&identifier.id)?;
    Ok(())
}
