use crate::entities::{ExportData, ExportParams, ExportPayload};
use crate::BlockManager;
use flowy_collaboration::entities::document_info::BlockDelta;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::convert::TryInto;
use std::sync::Arc;

pub(crate) async fn apply_delta_handler(
    data: Data<BlockDelta>,
    manager: AppData<Arc<BlockManager>>,
) -> DataResult<BlockDelta, FlowyError> {
    let block_delta = manager.receive_local_delta(data.into_inner()).await?;
    data_result(block_delta)
}

#[tracing::instrument(skip(data, manager), err)]
pub(crate) async fn export_handler(
    data: Data<ExportPayload>,
    manager: AppData<Arc<BlockManager>>,
) -> DataResult<ExportData, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let editor = manager.open_block(&params.view_id).await?;
    let delta_json = editor.delta_str().await?;
    data_result(ExportData {
        data: delta_json,
        export_type: params.export_type,
    })
}
