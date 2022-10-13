use crate::entities::{DocumentSnapshotPB, EditParams, EditPayloadPB, ExportDataPB, ExportParams, ExportPayloadPB};
use crate::DocumentEditorManager;
use flowy_error::FlowyError;
use flowy_sync::entities::text_block::DocumentIdPB;
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::convert::TryInto;
use std::sync::Arc;

pub(crate) async fn get_document_handler(
    data: Data<DocumentIdPB>,
    manager: AppData<Arc<DocumentEditorManager>>,
) -> DataResult<DocumentSnapshotPB, FlowyError> {
    let document_id: DocumentIdPB = data.into_inner();
    let editor = manager.open_document_editor(&document_id).await?;
    let operations_str = editor.get_operation_str().await?;
    data_result(DocumentSnapshotPB {
        doc_id: document_id.into(),
        snapshot: operations_str,
    })
}

pub(crate) async fn apply_edit_handler(
    data: Data<EditPayloadPB>,
    manager: AppData<Arc<DocumentEditorManager>>,
) -> Result<(), FlowyError> {
    let params: EditParams = data.into_inner().try_into()?;
    let _ = manager.apply_edit(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn export_handler(
    data: Data<ExportPayloadPB>,
    manager: AppData<Arc<DocumentEditorManager>>,
) -> DataResult<ExportDataPB, FlowyError> {
    let params: ExportParams = data.into_inner().try_into()?;
    let editor = manager.open_document_editor(&params.view_id).await?;
    let operations_str = editor.get_operation_str().await?;
    data_result(ExportDataPB {
        data: operations_str,
        export_type: params.export_type,
    })
}
