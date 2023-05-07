use collab::plugin_impl::rocks_disk::RocksDiskPlugin;
use collab::preclude::{Collab, CollabBuilder};

use collab_persistence::kv::rocks_kv::RocksCollabDB;
use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

use flowy_error::{FlowyError, FlowyResult};

use crate::document_data::DocumentDataWrapper;
use crate::{
  document::Document,
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
    tracing::debug!("create a document: {:?}", &doc_id);
    let collab = self.get_collab_for_doc_id(&doc_id)?;
    // create a new document with initial data.
    let document = Arc::new(Document::create_with_data(collab, data.0)?);
    Ok(document)
  }

  pub fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    tracing::debug!("open a document: {:?}", &doc_id);
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }
    let collab = self.get_collab_for_doc_id(&doc_id)?;
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
      tracing::debug!(
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
