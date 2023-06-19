use crate::FlowyError;
use collab_database::error::DatabaseError;
use collab_document::error::DocumentError;

impl From<DatabaseError> for FlowyError {
  fn from(error: DatabaseError) -> Self {
    FlowyError::internal().context(error)
  }
}

impl From<DocumentError> for FlowyError {
  fn from(error: DocumentError) -> Self {
    FlowyError::internal().context(error)
  }
}
