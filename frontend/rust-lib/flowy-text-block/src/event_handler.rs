use crate::entities::{EditParams, EditPayloadPB, ExportDataPB, ExportParams, ExportPayloadPB, TextBlockPB};
use crate::TextEditorManager;
use flowy_error::FlowyError;
use flowy_sync::entities::text_block::TextBlockIdPB;
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::convert::TryInto;
use std::sync::Arc;

pub(crate) async fn get_text_block_handler(
    data: Data<TextBlockIdPB>,
    manager: AppData<Arc<TextEditorManager>>,
) -> DataResult<TextBlockPB, FlowyError> {
    let text_block_id: TextBlockIdPB = data.into_inner();
    let editor = manager.open_text_editor(&text_block_id).await?;
    let delta_str = editor.delta_str().await?;
    data_result(TextBlockPB {
        text_block_id: text_block_id.into(),
        snapshot: delta_str,
    })
}

pub(crate) async fn apply_edit_handler(
    data: Data<EditPayloadPB>,
    manager: AppData<Arc<TextEditorManager>>,
) -> Result<(), FlowyError> {
    let params: EditParams = data.into_inner().try_into()?;
    let _ = manager.apply_edit(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn export_handler(
    data: Data<ExportPayloadPB>,
    manager: AppData<Arc<TextEditorManager>>,
) -> DataResult<ExportDataPB, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let editor = manager.open_text_editor(&params.view_id).await?;
    let delta_json = editor.delta_str().await?;
    data_result(ExportDataPB {
        data: delta_json,
        export_type: params.export_type,
    })
}
