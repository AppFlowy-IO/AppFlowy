use collab::core::collab::IndexContentReceiver;
use flowy_error::FlowyError;

pub struct IndexableData {
  pub id: String,
  pub data: String,
}

pub trait IndexManager: Send + Sync {
  fn set_index_content_receiver(&self, rx: IndexContentReceiver);
  fn add_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  fn update_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError>;
}
