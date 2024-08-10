use crate::entities::{
  DocEventPB, DocumentAwarenessStatesPB, DocumentSnapshotStatePB, DocumentSyncStatePB,
};
use crate::notification::{send_notification, DocumentNotification};
use collab::preclude::Collab;
use collab_document::document::Document;
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;

pub fn subscribe_document_changed(doc_id: &str, document: &mut Document) {
  let doc_id_clone_for_block_changed = doc_id.to_owned();
  document.subscribe_block_changed("key", move |events, is_remote| {
    #[cfg(feature = "verbose_log")]
    tracing::trace!("subscribe_document_changed: {:?}", events);

    // send notification to the client.
    send_notification(
      &doc_id_clone_for_block_changed,
      DocumentNotification::DidReceiveUpdate,
    )
    .payload::<DocEventPB>((events, is_remote, None).into())
    .send();
  });

  let doc_id_clone_for_awareness_state = doc_id.to_owned();
  document.subscribe_awareness_state("key", move |events| {
    #[cfg(feature = "verbose_log")]
    tracing::trace!("subscribe_awareness_state: {:?}", events);
    send_notification(
      &doc_id_clone_for_awareness_state,
      DocumentNotification::DidUpdateDocumentAwarenessState,
    )
    .payload::<DocumentAwarenessStatesPB>(events.into())
    .send();
  });
}

pub fn subscribe_document_snapshot_state(collab: &Collab) {
  let document_id = collab.object_id().to_string();
  let mut snapshot_state = collab.subscribe_snapshot_state();
  af_spawn(async move {
    while let Some(snapshot_state) = snapshot_state.next().await {
      if let Some(new_snapshot_id) = snapshot_state.snapshot_id() {
        tracing::debug!("Did create document remote snapshot: {}", new_snapshot_id);
        send_notification(
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
  af_spawn(async move {
    while let Some(sync_state) = sync_state_stream.next().await {
      send_notification(
        &document_id,
        DocumentNotification::DidUpdateDocumentSyncState,
      )
      .payload(DocumentSyncStatePB::from(sync_state))
      .send();
    }
  });
}
