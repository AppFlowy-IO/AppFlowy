use std::{collections::HashMap, sync::Arc};

use collab::{plugin_impl::disk::CollabDiskPlugin, preclude::CollabBuilder};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use parking_lot::RwLock;

use crate::{
  document::{Document, DocumentDataWrapper},
  notification::{send_notification, DocumentNotification},
};

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

  pub fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }
    let collab = self.get_collab_for_doc_id(&doc_id)?;
    let data = DocumentDataWrapper::default();
    let document = Arc::new(Document::new(collab, data)?);

    let clone_doc_id = doc_id.clone();
    let _document_data = document
      .lock()
      .open(move |_, _| {
        // TODO: add payload data.
        send_notification(&clone_doc_id, DocumentNotification::DidReceiveUpdate).send();
      })
      .map_err(|err| FlowyError::internal().context(err))?;
    self.documents.write().insert(doc_id, document.clone());
    Ok(document)
  }

  pub fn close_document(&self, doc_id: String) -> FlowyResult<()> {
    self.documents.write().remove(&doc_id);
    Ok(())
  }

  fn get_collab_for_doc_id(&self, doc_id: &str) -> Result<collab::preclude::Collab, FlowyError> {
    let uid = self.user.user_id()?;
    let kv_db = self.user.kv_db()?;
    let mut collab = CollabBuilder::new(uid, doc_id).build();
    let disk_plugin = Arc::new(
      CollabDiskPlugin::new(uid, kv_db).map_err(|err| FlowyError::internal().context(err))?,
    );
    collab.add_plugin(disk_plugin);
    collab.initial();
    Ok(collab)
  }
}
