use std::{collections::HashMap, sync::Arc};

use collab::{plugin_impl::disk::CollabDiskPlugin, preclude::CollabBuilder};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use parking_lot::RwLock;

use crate::{
  document::{Document, DocumentDataWrapper},
  notification::{send_notification, DocumentNotification},
  entities::{DocEventPB, BlockEventPB},
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

  pub fn create_document(&self, doc_id: String, data: DocumentDataWrapper) -> FlowyResult<Arc<Document>> {
    self.initial_document(doc_id, Some(data))
  }

  fn initial_document(&self, doc_id: String, data: Option<DocumentDataWrapper>) -> FlowyResult<Arc<Document>> {
    let collab = self.get_collab_for_doc_id(&doc_id)?;
    let document = match data {
      Some(data) => Document::create_with_data(collab, data.0).map_err(|err| FlowyError::internal().context(err))?,
      None => Document::new(collab).map_err(|err| FlowyError::internal().context(err))?,
    };
    let document = Arc::new(document);

    let clone_doc_id = doc_id.clone();
    document
        .lock()
        .open(move |events, is_remote| {

          send_notification(&clone_doc_id, DocumentNotification::DidReceiveUpdate)
              .payload(DocEventPB {
                events: events
                    .iter()
                    .map(|block_event| BlockEventPB { event: block_event.to_owned().iter().map(|e| e.to_owned().into()).collect() })
                    .collect(),
                is_remote: is_remote.to_owned(),
              })
              .send();

        })
        .map_err(|err| FlowyError::internal().context(err))?;
    self.documents.write().insert(doc_id.clone(), document.clone());

    Ok(document)
  }

  pub fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    tracing::debug!("open_document: {:?}", &doc_id);
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }

    let document = self.initial_document(doc_id.clone(), None)?;

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
