use std::{
  ops::{Deref, DerefMut},
  sync::Arc,
};

use collab::core::collab::MutexCollab;
use collab_document::{blocks::DocumentData, document::Document};
use futures::StreamExt;
use parking_lot::Mutex;
use tokio_stream::wrappers::WatchStream;

use crate::entities::{DocumentSnapshotPB, DocumentSnapshotStatePB};
use crate::notification::{send_notification, DocumentNotification};
use flowy_error::FlowyResult;

/// This struct wrap the document::Document
#[derive(Clone)]
pub struct DocumentEditor(Arc<Mutex<Document>>);

impl DocumentEditor {
  /// Creates and returns a new Document object.
  /// # Arguments
  /// * `collab` - the identifier of the collaboration instance
  ///
  /// # Returns
  /// * `Result<Document, FlowyError>` - a Result containing either a new Document object or an Error if the document creation failed
  pub fn new(collab: Arc<MutexCollab>) -> FlowyResult<Self> {
    let document =
      Document::create(collab.clone()).map(|inner| Self(Arc::new(Mutex::new(inner))))?;
    listen_on_document_snapshot_state(&collab);
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
    let document = Document::create_with_data(collab.clone(), data)
      .map(|inner| Self(Arc::new(Mutex::new(inner))))?;
    listen_on_document_snapshot_state(&collab);
    Ok(document)
  }
}

fn listen_on_document_snapshot_state(collab: &Arc<MutexCollab>) {
  let document_id = collab.lock().object_id.clone();
  let mut snapshot_state = WatchStream::new(collab.lock().subscribe_snapshot_state());
  tokio::spawn(async move {
    while let Some(snapshot_state) = snapshot_state.next().await {
      send_notification(
        &document_id,
        DocumentNotification::DidUpdateDocumentSnapshotState,
      )
      .payload(DocumentSnapshotStatePB::from(snapshot_state))
      .send();
    }
  });
}

unsafe impl Sync for DocumentEditor {}
unsafe impl Send for DocumentEditor {}

impl Deref for DocumentEditor {
  type Target = Arc<Mutex<Document>>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for DocumentEditor {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}
