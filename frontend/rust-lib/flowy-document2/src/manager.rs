use std::{collections::HashMap, sync::Arc};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;
use collab_document::blocks::DocumentData;
use collab_document::error::DocumentError;
use collab_document::YrsDocAction;
use parking_lot::RwLock;

use flowy_error::{FlowyError, FlowyResult};

use crate::{
  document::Document,
  document_data::default_document_data,
  entities::DocEventPB,
  notification::{send_notification, DocumentNotification},
};

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>; // unused now.
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

pub struct DocumentManager {
  user: Arc<dyn DocumentUser>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  documents: Arc<RwLock<HashMap<String, Arc<Document>>>>,
}

impl DocumentManager {
  pub fn new(user: Arc<dyn DocumentUser>, collab_builder: Arc<AppFlowyCollabBuilder>) -> Self {
    Self {
      user,
      collab_builder,
      documents: Default::default(),
    }
  }

  /// Create a new document.
  ///
  /// if the document already exists, return the existing document.
  /// if the data is None, will create a document with default data.
  pub fn create_document(
    &self,
    doc_id: &str,
    data: Option<DocumentData>,
  ) -> FlowyResult<Arc<Document>> {
    tracing::debug!("create a document: {:?}", doc_id);
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, doc_id, "document", db);
    let data = data.unwrap_or_else(default_document_data);
    let document = Arc::new(Document::create_with_data(collab, data)?);
    Ok(document)
  }

  /// get document
  /// read the existing document from the map if it exists, otherwise read it from the disk and write it to the map.
  pub fn get_or_open_document(&self, doc_id: &str) -> FlowyResult<Arc<Document>> {
    if let Some(doc) = self.documents.read().get(doc_id) {
      return Ok(doc.clone());
    }
    tracing::debug!("open_document: {:?}", doc_id);
    // read the existing document from the disk.
    let document = self.get_document_from_disk(doc_id)?;
    // save the document to the memory and read it from the memory if we open the same document again.
    // and we don't want to subscribe to the document changes if we open the same document again.
    self
      .documents
      .write()
      .insert(doc_id.to_string(), document.clone());

    // subscribe to the document changes.
    self.subscribe_document_changes(document.clone(), doc_id)?;

    Ok(document)
  }

  pub fn subscribe_document_changes(
    &self,
    document: Arc<Document>,
    doc_id: &str,
  ) -> Result<DocumentData, DocumentError> {
    let mut document = document.lock();
    let doc_id = doc_id.to_string();
    document.open(move |events, is_remote| {
      tracing::trace!(
        "document changed: {:?}, from remote: {}",
        &events,
        is_remote
      );
      // send notification to the client.
      send_notification(&doc_id, DocumentNotification::DidReceiveUpdate)
        .payload::<DocEventPB>((events, is_remote).into())
        .send();
    })
  }

  /// get document
  /// read the existing document from the disk.
  pub fn get_document_from_disk(&self, doc_id: &str) -> FlowyResult<Arc<Document>> {
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, doc_id, "document", db);
    // read the existing document from the disk.
    let document = Arc::new(Document::new(collab)?);
    Ok(document)
  }

  pub fn close_document(&self, doc_id: &str) -> FlowyResult<()> {
    self.documents.write().remove(doc_id);
    Ok(())
  }

  pub fn delete_document(&self, doc_id: &str) -> FlowyResult<()> {
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let _ = db.with_write_txn(|txn| {
      txn.delete_doc(uid, &doc_id)?;
      Ok(())
    });
    self.documents.write().remove(doc_id);
    Ok(())
  }
}
