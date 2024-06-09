use crate::entities::{
  DocEventPB, DocumentAwarenessStatesPB, DocumentSnapshotStatePB, DocumentSyncStatePB,
};
use crate::notification::{send_notification, DocumentNotification};
use collab::core::collab::MutexCollab;
use collab_document::document::DocumentIndexContent;
use collab_document::{blocks::DocumentData, document::Document};
use flowy_error::FlowyResult;
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;
use parking_lot::Mutex;
use std::{
  ops::{Deref, DerefMut},
  sync::Arc,
};
use tracing::{instrument, warn};

/// This struct wrap the document::Document
#[derive(Clone)]
pub struct MutexDocument(Arc<Mutex<Document>>);

impl MutexDocument {
  /// Open a document with the given collab.
  /// # Arguments
  /// * `collab` - the identifier of the collaboration instance
  ///
  /// # Returns
  /// * `Result<Document, FlowyError>` - a Result containing either a new Document object or an Error if the document creation failed
  pub fn open(doc_id: &str, collab: Arc<MutexCollab>) -> FlowyResult<Self> {
    #[allow(clippy::arc_with_non_send_sync)]
    let document = Document::open(collab.clone()).map(|inner| Self(Arc::new(Mutex::new(inner))))?;
    subscribe_document_changed(doc_id, &document);
    subscribe_document_snapshot_state(&collab);
    subscribe_document_sync_state(&collab);
    Ok(document)
  }

  /// Creates and returns a new Document object with initial data.
  /// # Arguments
  /// * `collab` - the identifier of the collaboration instance
  /// * `data` - the initial data to include in the document
  ///
  /// # Returns
  /// * `Result<Document, FlowyError>` - a Result containing either a new Document object or an Error if the document creation failed
  pub fn create_with_data(collab: Arc<MutexCollab>, data: DocumentData) -> FlowyResult<Self> {
    #[allow(clippy::arc_with_non_send_sync)]
    let document =
      Document::create_with_data(collab, data).map(|inner| Self(Arc::new(Mutex::new(inner))))?;
    Ok(document)
  }

  #[instrument(level = "debug", skip_all)]
  pub fn start_init_sync(&self) {
    if let Some(document) = self.0.try_lock() {
      if let Some(collab) = document.get_collab().try_lock() {
        collab.start_init_sync();
      } else {
        warn!("Failed to start init sync, collab is locked");
      }
    } else {
      warn!("Failed to start init sync, document is locked");
    }
  }
}

fn subscribe_document_changed(doc_id: &str, document: &MutexDocument) {
  let doc_id_clone_for_block_changed = doc_id.to_owned();
  document
    .lock()
    .subscribe_block_changed(move |events, is_remote| {
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
  document.lock().subscribe_awareness_state(move |events| {
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

fn subscribe_document_snapshot_state(collab: &Arc<MutexCollab>) {
  let document_id = collab.lock().object_id.clone();
  let mut snapshot_state = collab.lock().subscribe_snapshot_state();
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

fn subscribe_document_sync_state(collab: &Arc<MutexCollab>) {
  let document_id = collab.lock().object_id.clone();
  let mut sync_state_stream = collab.lock().subscribe_sync_state();
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

unsafe impl Sync for MutexDocument {}
unsafe impl Send for MutexDocument {}

impl Deref for MutexDocument {
  type Target = Arc<Mutex<Document>>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for MutexDocument {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl From<&MutexDocument> for DocumentIndexContent {
  fn from(doc: &MutexDocument) -> Self {
    let doc = doc.lock();
    DocumentIndexContent::from(&*doc)
  }
}
