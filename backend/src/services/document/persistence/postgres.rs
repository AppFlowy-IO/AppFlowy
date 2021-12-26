use crate::{context::FlowyPersistence, services::document::persistence::DocumentKVPersistence};
use anyhow::Context;
use backend_service::errors::{internal_error, ServerError};
use flowy_collaboration::protobuf::{
    CreateDocParams,
    DocIdentifier,
    DocumentInfo,
    RepeatedRevision,
    ResetDocumentParams,
};
use lib_ot::{core::OperationTransformable, rich_text::RichTextDelta};
use sqlx::PgPool;
use std::sync::Arc;
use uuid::Uuid;

#[tracing::instrument(level = "debug", skip(kv_store), err)]
pub(crate) async fn create_doc(
    kv_store: &Arc<DocumentKVPersistence>,
    mut params: CreateDocParams,
) -> Result<(), ServerError> {
    let revisions = params.take_revisions().take_items();
    let _ = kv_store.batch_set_revision(revisions.into()).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(persistence), err)]
pub(crate) async fn read_doc(
    persistence: &Arc<FlowyPersistence>,
    params: DocIdentifier,
) -> Result<DocumentInfo, ServerError> {
    let _ = Uuid::parse_str(&params.doc_id).context("Parse document id to uuid failed")?;

    let kv_store = persistence.kv_store();
    let revisions = kv_store.batch_get_revisions(&params.doc_id, None).await?;
    make_doc_from_revisions(&params.doc_id, revisions)
}

#[tracing::instrument(level = "debug", skip(_pool, _params), fields(delta), err)]
pub async fn reset_document(_pool: &PgPool, _params: ResetDocumentParams) -> Result<(), ServerError> {
    unimplemented!()
}

#[tracing::instrument(level = "debug", skip(kv_store), err)]
pub(crate) async fn delete_doc(kv_store: &Arc<DocumentKVPersistence>, doc_id: Uuid) -> Result<(), ServerError> {
    let _ = kv_store.batch_delete_revisions(&doc_id.to_string(), None).await?;
    Ok(())
}

#[derive(Debug, Clone, sqlx::FromRow)]
struct DocTable {
    id: uuid::Uuid,
    rev_id: i64,
}

fn make_doc_from_revisions(doc_id: &str, mut revisions: RepeatedRevision) -> Result<DocumentInfo, ServerError> {
    let revisions = revisions.take_items();
    if revisions.is_empty() {
        return Err(ServerError::record_not_found().context(format!("{} not exist", doc_id)));
    }
    
    let mut document_delta = RichTextDelta::new();
    let mut base_rev_id = 0;
    let mut rev_id = 0;
    // TODO: generate delta from revision should be wrapped into function.
    for revision in revisions {
        base_rev_id = revision.base_rev_id;
        rev_id = revision.rev_id;
        let delta = RichTextDelta::from_bytes(revision.delta_data).map_err(internal_error)?;
        document_delta = document_delta.compose(&delta).map_err(internal_error)?;
    }
    let text = document_delta.to_json();
    let mut document_info = DocumentInfo::new();
    document_info.set_doc_id(doc_id.to_owned());
    document_info.set_text(text);
    document_info.set_base_rev_id(base_rev_id);
    document_info.set_rev_id(rev_id);
    Ok(document_info)
}
