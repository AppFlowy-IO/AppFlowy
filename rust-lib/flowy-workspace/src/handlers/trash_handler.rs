use crate::{
    entities::{trash::RepeatedTrash, view::RepeatedView},
    errors::WorkspaceError,
    services::TrashCan,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn read_trash_handler(controller: Unit<Arc<TrashCan>>) -> DataResult<RepeatedTrash, WorkspaceError> {
    let repeated_trash = controller.read_trash()?;
    data_result(repeated_trash)
}
