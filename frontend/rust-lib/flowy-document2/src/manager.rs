use collab::plugin_impl::rocks_disk::RocksDiskPlugin;
use collab::preclude::{Collab, CollabBuilder};
use collab_persistence::kv::rocks_kv::RocksCollabDB;
use flowy_error::{FlowyError, FlowyResult};
use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

use crate::{
  document::{Document, DocumentDataWrapper},
  entities::DocEventPB,
  notification::{send_notification, DocumentNotification},
};

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>; // unused now.
  fn kv_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
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

  pub fn create_document(
    &self,
    doc_id: String,
    data: DocumentDataWrapper,
  ) -> FlowyResult<Arc<Document>> {
    let collab = self.get_collab_for_doc_id(&doc_id)?;
    let document = Arc::new(Document::create_with_data(collab, data.0)?);
    self
      .documents
      .write()
      .insert(doc_id.clone(), document.clone());
    Ok(document)
  }

  pub fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }
    tracing::debug!("open_document: {:?}", &doc_id);
    let collab = self.get_collab_for_doc_id(&doc_id)?;
    let document = Arc::new(Document::new(collab)?);

    let clone_doc_id = doc_id.clone();
    document
      .lock()
      .open(move |events, is_remote| {
        send_notification(&clone_doc_id, DocumentNotification::DidReceiveUpdate)
          .payload(DocEventPB::get_from(events, is_remote))
          .send();
      })
      .map_err(|err| FlowyError::internal().context(err))?;
    self
      .documents
      .write()
      .insert(doc_id.clone(), document.clone());
    Ok(document)
  }

  pub fn close_document(&self, doc_id: String) -> FlowyResult<()> {
    self.documents.write().remove(&doc_id);
    Ok(())
  }

  fn get_collab_for_doc_id(&self, doc_id: &str) -> Result<Collab, FlowyError> {
    let uid = self.user.user_id()?;
    let kv_db = self.user.kv_db()?;
    let mut collab = CollabBuilder::new(uid, doc_id).build();
    let disk_plugin = Arc::new(
      RocksDiskPlugin::new(uid, kv_db).map_err(|err| FlowyError::internal().context(err))?,
    );
    collab.add_plugin(disk_plugin);
    collab.initial();
    Ok(collab)
  }
}
