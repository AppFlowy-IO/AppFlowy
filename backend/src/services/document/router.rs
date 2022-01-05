use crate::{
    context::FlowyPersistence,
    services::document::persistence::{create_document, read_document, reset_document},
    util::serde_ext::parse_from_payload,
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use backend_service::{errors::ServerError, response::FlowyResponse};
<<<<<<< HEAD
<<<<<<< HEAD
use flowy_collaboration::protobuf::{CreateDocParams, DocumentId, ResetDocumentParams};

=======
=======
>>>>>>> upstream/main
use flowy_collaboration::{
    protobuf::{
        CreateDocParams as CreateDocParamsPB,
        DocumentId as DocumentIdPB,
        ResetDocumentParams as ResetDocumentParamsPB,
    },
    sync::ServerDocumentManager,
};
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
use std::sync::Arc;

pub async fn create_document_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
<<<<<<< HEAD
<<<<<<< HEAD
    let params: CreateDocParams = parse_from_payload(payload).await?;
=======
    let params: CreateDocParamsPB = parse_from_payload(payload).await?;
>>>>>>> upstream/main
=======
    let params: CreateDocParamsPB = parse_from_payload(payload).await?;
>>>>>>> upstream/main
    let kv_store = persistence.kv_store();
    let _ = create_document(&kv_store, params).await?;
    Ok(FlowyResponse::success().into())
}

#[tracing::instrument(level = "debug", skip(payload, persistence), err)]
pub async fn read_document_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
<<<<<<< HEAD
<<<<<<< HEAD
    let params: DocumentId = parse_from_payload(payload).await?;
=======
    let params: DocumentIdPB = parse_from_payload(payload).await?;
>>>>>>> upstream/main
=======
    let params: DocumentIdPB = parse_from_payload(payload).await?;
>>>>>>> upstream/main
    let kv_store = persistence.kv_store();
    let doc = read_document(&kv_store, params).await?;
    let response = FlowyResponse::success().pb(doc)?;
    Ok(response.into())
}

pub async fn reset_document_handler(
    payload: Payload,
<<<<<<< HEAD
<<<<<<< HEAD
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: ResetDocumentParams = parse_from_payload(payload).await?;
    let kv_store = persistence.kv_store();
    let _ = reset_document(&kv_store, params).await?;
=======
=======
>>>>>>> upstream/main
    document_manager: Data<Arc<ServerDocumentManager>>,
) -> Result<HttpResponse, ServerError> {
    let params: ResetDocumentParamsPB = parse_from_payload(payload).await?;
    let _ = reset_document(document_manager.get_ref(), params).await?;
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
    Ok(FlowyResponse::success().into())
}
