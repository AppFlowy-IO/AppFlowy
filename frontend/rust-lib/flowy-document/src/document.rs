use crate::entities::{
  DocEventPB, DocumentAwarenessStatesPB, DocumentSnapshotStatePB, DocumentSyncStatePB,
};
use crate::notification::{DocumentNotification, document_notification_builder};
use collab::preclude::Collab;
use collab_document::document::Document;
use futures::StreamExt;
use lib_infra::sync_trace;
use uuid::Uuid;

pub fn subscribe_document_changed(doc_id: &Uuid, document: &mut Document) {
  let doc_id_clone_for_block_changed = doc_id.to_string();
  document.subscribe_block_changed("key", move |events, is_remote| {
    sync_trace!(
      "[Document] block changed in doc_id: {}, is_remote: {}, events: {:?}",
      doc_id_clone_for_block_changed,
      is_remote,
      events
    );

    // send notification to the client.
    document_notification_builder(
      &doc_id_clone_for_block_changed,
      DocumentNotification::DidReceiveUpdate,
    )
    .payload::<DocEventPB>((events, is_remote, None).into())
    .send();
  });

  let doc_id_clone_for_awareness_state = doc_id.to_owned();
  document.subscribe_awareness_state("key", move |events| {
    sync_trace!(
      "[Document] awareness state in doc_id: {}, events: {:?}",
      doc_id_clone_for_awareness_state,
      events
    );

    document_notification_builder(
      &doc_id_clone_for_awareness_state.to_string(),
      DocumentNotification::DidUpdateDocumentAwarenessState,
    )
    .payload::<DocumentAwarenessStatesPB>(events.into())
    .send();
  });
}

pub fn subscribe_document_snapshot_state(collab: &Collab) {
  let document_id = collab.object_id().to_string();
  let mut snapshot_state = collab.subscribe_snapshot_state();
  tokio::spawn(async move {
    while let Some(snapshot_state) = snapshot_state.next().await {
      if let Some(new_snapshot_id) = snapshot_state.snapshot_id() {
        tracing::debug!("Did create document remote snapshot: {}", new_snapshot_id);
        document_notification_builder(
          &document_id,
          DocumentNotification::DidUpdateDocumentSnapshotState,
        )
        .payload(DocumentSnapshotStatePB { new_snapshot_id })
        .send();
      }
    }
  });
}

pub fn subscribe_document_sync_state(collab: &Collab) {
  let document_id = collab.object_id().to_string();
  let mut sync_state_stream = collab.subscribe_sync_state();
  tokio::spawn(async move {
    while let Some(sync_state) = sync_state_stream.next().await {
      document_notification_builder(
        &document_id,
        DocumentNotification::DidUpdateDocumentSyncState,
      )
      .payload(DocumentSyncStatePB::from(sync_state))
      .send();
    }
  });
}
