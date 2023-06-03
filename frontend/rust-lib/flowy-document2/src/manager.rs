use std::{collections::HashMap, sync::Arc};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;
use collab_document::blocks::DocumentData;
use parking_lot::RwLock;

use flowy_error::{FlowyError, FlowyResult};

use crate::{
  document::Document,
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

  pub fn create_document(&self, doc_id: String, data: DocumentData) -> FlowyResult<Arc<Document>> {
    tracing::debug!("create a document: {:?}", &doc_id);
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, &doc_id, "document", db);
    let document = Arc::new(Document::create_with_data(collab, data)?);
    Ok(document)
  }

  pub fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    tracing::debug!("open a document: {:?}", &doc_id);
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }
    tracing::debug!("open_document: {:?}", &doc_id);
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, &doc_id, "document", db);
    // read the existing document from the disk.
    let document = Arc::new(Document::new(collab)?);
    // save the document to the memory and read it from the memory if we open the same document again.
    // and we don't want to subscribe to the document changes if we open the same document again.
    self
      .documents
      .write()
      .insert(doc_id.clone(), document.clone());

    // subscribe to the document changes.
    document.lock().open(move |events, is_remote| {
      tracing::trace!(
        "document changed: {:?}, from remote: {}",
        &events,
        is_remote
      );
      // send notification to the client.
      send_notification(&doc_id, DocumentNotification::DidReceiveUpdate)
        .payload::<DocEventPB>((events, is_remote).into())
        .send();
    })?;

    Ok(document)
  }

  pub fn get_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, &doc_id, "document", db);
    // read the existing document from the disk.
    let document = Arc::new(Document::new(collab)?);
    Ok(document)
  }

  pub fn close_document(&self, doc_id: String) -> FlowyResult<()> {
    self.documents.write().remove(&doc_id);
    Ok(())
  }
}
