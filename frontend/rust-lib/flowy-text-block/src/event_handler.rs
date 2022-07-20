use crate::entities::{ExportDataPB, ExportParams, ExportPayloadPB};
use crate::TextBlockManager;
use flowy_error::FlowyError;
use flowy_sync::entities::text_block::{TextBlockDeltaPB, TextBlockIdPB};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::convert::TryInto;
use std::sync::Arc;

pub(crate) async fn get_block_data_handler(
    data: Data<TextBlockIdPB>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<TextBlockDeltaPB, FlowyError> {
    let block_id: TextBlockIdPB = data.into_inner();
    let editor = manager.open_block(&block_id).await?;
    let delta_str = editor.delta_str().await?;
    data_result(TextBlockDeltaPB {
        block_id: block_id.into(),
        delta_str,
    })
}

pub(crate) async fn apply_delta_handler(
    data: Data<TextBlockDeltaPB>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<TextBlockDeltaPB, FlowyError> {
    let block_delta = manager.receive_local_delta(data.into_inner()).await?;
    data_result(block_delta)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn export_handler(
    data: Data<ExportPayloadPB>,
    manager: AppData<Arc<TextBlockManager>>,
) -> DataResult<ExportDataPB, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let editor = manager.open_block(&params.view_id).await?;
    let delta_json = editor.delta_str().await?;
    data_result(ExportDataPB {
        data: delta_json,
        export_type: params.export_type,
    })
}
