use crate::entities::{ExportData, ExportParams, ExportPayload};
use crate::TextBlockManager;
use flowy_error::FlowyError;
use flowy_sync::entities::text_block::{TextBlockDelta, TextBlockId};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::convert::TryInto;
use std::sync::Arc;

pub(crate) async fn get_block_data_handler(
    data: Data<TextBlockId>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<TextBlockDelta, FlowyError> {
    let block_id: TextBlockId = data.into_inner();
    let editor = manager.open_block(&block_id).await?;
    let delta_str = editor.delta_str().await?;
    data_result(TextBlockDelta {
        block_id: block_id.into(),
        delta_str,
    })
}

pub(crate) async fn apply_delta_handler(
    data: Data<TextBlockDelta>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<TextBlockDelta, FlowyError> {
    let block_delta = manager.receive_local_delta(data.into_inner()).await?;
    data_result(block_delta)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn export_handler(
    data: Data<ExportPayload>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<ExportData, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let editor = manager.open_block(&params.view_id).await?;
    let delta_json = editor.delta_str().await?;
    data_result(ExportData {
        data: delta_json,
        export_type: params.export_type,
    })
}
