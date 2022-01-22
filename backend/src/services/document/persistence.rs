use anyhow::Context;
use backend_service::errors::{internal_error, ServerError};

use flowy_collaboration::{
    protobuf::{CreateDocParams, DocumentId, DocumentInfo, ResetDocumentParams},
    server_document::ServerDocumentManager,
    util::make_document_info_pb_from_revisions_pb,
};

use crate::services::kv::revision_kv::RevisionKVPersistence;
use std::sync::Arc;
use uuid::Uuid;

#[tracing::instrument(level = "debug", skip(document_store, params), err)]
pub(crate) async fn create_document(
    document_store: &Arc<RevisionKVPersistence>,
    mut params: CreateDocParams,
) -> Result<(), ServerError> {
    let revisions = params.take_revisions().take_items();
    let _ = document_store.set_revision(revisions.into()).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(document_store), err)]
pub async fn read_document(
    document_store: &Arc<RevisionKVPersistence>,
    params: DocumentId,
) -> Result<DocumentInfo, ServerError> {
    let _ = Uuid::parse_str(&params.doc_id).context("Parse document id to uuid failed")?;
    let revisions = document_store.get_revisions(&params.doc_id, None).await?;
    match make_document_info_pb_from_revisions_pb(&params.doc_id, revisions) {
        Ok(Some(document_info)) => Ok(document_info),
        Ok(None) => Err(ServerError::record_not_found().context(format!("{} not exist", params.doc_id))),
        Err(e) => Err(ServerError::internal().context(e)),
    }
}

#[tracing::instrument(level = "debug", skip(document_manager, params), fields(delta), err)]
pub async fn reset_document(
    document_manager: &Arc<ServerDocumentManager>,
    mut params: ResetDocumentParams,
) -> Result<(), ServerError> {
    let repeated_revision = params.take_revisions();
    if repeated_revision.get_items().is_empty() {
        return Err(ServerError::payload_none().context("Revisions should not be empty when reset the document"));
    }
    let doc_id = params.doc_id.clone();
    let _ = document_manager
        .handle_document_reset(&doc_id, repeated_revision)
        .await
        .map_err(internal_error)?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(document_store), err)]
pub(crate) async fn delete_document(
    document_store: &Arc<RevisionKVPersistence>,
    doc_id: Uuid,
) -> Result<(), ServerError> {
    // TODO: delete revisions may cause time issue. Maybe delete asynchronously?
    let _ = document_store.delete_revisions(&doc_id.to_string(), None).await?;
    Ok(())
}
