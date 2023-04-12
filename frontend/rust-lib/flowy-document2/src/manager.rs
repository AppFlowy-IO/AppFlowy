use std::{collections::HashMap, sync::Arc};

use collab::{plugin_impl::disk::CollabDiskPlugin, preclude::CollabBuilder};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use parking_lot::RwLock;

use crate::document::{Document, DocumentDataWrapper};

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>; // unused now.
  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError>;
}

pub struct DocumentManager {
  documents: Arc<RwLock<HashMap<String, Arc<Document>>>>,
  user: Arc<dyn DocumentUser>,
}

// unsafe impl Send for DocumentManager {}
// unsafe impl Sync for DocumentManager {}

impl DocumentManager {
  pub fn new(user: Arc<dyn DocumentUser>) -> Self {
    Self {
      documents: Default::default(),
      user,
    }
  }

  pub fn open_document(&self, doc_id: &str) -> FlowyResult<Arc<Document>> {
    if let Some(doc) = self.documents.read().get(doc_id) {
      return Ok(doc.clone());
    }
    let uid = self.user.user_id()?;
    let kv_db = self.user.kv_db()?;
    let mut collab = CollabBuilder::new(uid, doc_id).build();
    let disk_plugin = Arc::new(
      CollabDiskPlugin::new(uid, kv_db).map_err(|err| FlowyError::internal().context(err))?,
    );
    collab.add_plugin(disk_plugin);
    collab.initial();
    let data = DocumentDataWrapper::default();
    let document = Arc::new(Document::new(collab, data)?);
    let documentData = document
      .lock()
      .open(|_, _| {})
      .map_err(|err| FlowyError::internal().context(err))?;
    self
      .documents
      .write()
      .insert(doc_id.to_string(), document.clone());
    Ok(document)
  }
}
