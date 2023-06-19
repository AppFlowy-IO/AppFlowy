use std::{
  ops::{Deref, DerefMut},
  sync::Arc,
};

use collab::core::collab::MutexCollab;
use collab_document::{blocks::DocumentData, document::Document as InnerDocument};
use parking_lot::Mutex;

use flowy_error::FlowyResult;

/// This struct wrap the document::Document
#[derive(Clone)]
pub struct Document(Arc<Mutex<InnerDocument>>);

impl Document {
  /// Creates and returns a new Document object.
  /// # Arguments
  /// * `collab` - the identifier of the collaboration instance
  ///
  /// # Returns
  /// * `Result<Document, FlowyError>` - a Result containing either a new Document object or an Error if the document creation failed
  pub fn new(collab: Arc<MutexCollab>) -> FlowyResult<Self> {
    InnerDocument::create(collab)
      .map(|inner| Self(Arc::new(Mutex::new(inner))))
      .map_err(|err| err.into())
  }

  /// Creates and returns a new Document object with initial data.
  /// # Arguments
  /// * `collab` - the identifier of the collaboration instance
  /// * `data` - the initial data to include in the document
  ///
  /// # Returns
  /// * `Result<Document, FlowyError>` - a Result containing either a new Document object or an Error if the document creation failed
  pub fn create_with_data(collab: Arc<MutexCollab>, data: DocumentData) -> FlowyResult<Self> {
    InnerDocument::create_with_data(collab, data)
      .map(|inner| Self(Arc::new(Mutex::new(inner))))
      .map_err(|err| err.into())
  }
}

unsafe impl Sync for Document {}
unsafe impl Send for Document {}

impl Deref for Document {
  type Target = Arc<Mutex<InnerDocument>>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for Document {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}
