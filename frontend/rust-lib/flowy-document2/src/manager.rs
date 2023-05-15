use std::{collections::HashMap, sync::Arc};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;

use parking_lot::RwLock;

use flowy_error::{FlowyError, FlowyResult};

use crate::{
  document::{Document, DocumentDataWrapper},
  entities::DocEventPB,
  notification::{send_notification, DocumentNotification},
};

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>; // unused now.
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

pub struct DocumentManager {
  user: Arc<dyn DocumentUser>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  documents: Arc<RwLock<HashMap<String, Arc<Document>>>>,
}

unsafe impl Send for DocumentManager {}
unsafe impl Sync for DocumentManager {}

impl DocumentManager {
  pub fn new(user: Arc<dyn DocumentUser>, collab_builder: Arc<AppFlowyCollabBuilder>) -> Self {
    Self {
      user,
      collab_builder,
      documents: Default::default(),
    }
  }

  pub async fn create_document(
    &self,
    doc_id: String,
    data: DocumentDataWrapper,
  ) -> FlowyResult<Arc<Document>> {
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, &doc_id, db);
    let document = Arc::new(Document::create_with_data(collab, data.0)?);
    self.documents.write().insert(doc_id, document.clone());
    Ok(document)
  }

  pub async fn open_document(&self, doc_id: String) -> FlowyResult<Arc<Document>> {
    if let Some(doc) = self.documents.read().get(&doc_id) {
      return Ok(doc.clone());
    }
    tracing::debug!("open_document: {:?}", &doc_id);
    let uid = self.user.user_id()?;
    let db = self.user.collab_db()?;
    let collab = self.collab_builder.build(uid, &doc_id, db);
    let document = Arc::new(Document::new(collab)?);

    let clone_doc_id = doc_id.clone();
    document
      .lock()
      .open(move |events, is_remote| {
        tracing::debug!("data_change: {:?}, from remote: {}", &events, is_remote);
        send_notification(&clone_doc_id, DocumentNotification::DidReceiveUpdate)
          .payload::<DocEventPB>((events, is_remote).into())
          .send();
      })
      .map_err(|err| FlowyError::internal().context(err))?;
    self.documents.write().insert(doc_id, document.clone());
    Ok(document)
  }

  pub fn close_document(&self, doc_id: String) -> FlowyResult<()> {
    self.documents.write().remove(&doc_id);
    Ok(())
  }
}
