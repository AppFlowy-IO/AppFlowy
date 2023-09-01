use collab_database::error::DatabaseError;
use collab_document::error::DocumentError;

use crate::FlowyError;

impl From<DatabaseError> for FlowyError {
  fn from(error: DatabaseError) -> Self {
    FlowyError::internal().with_context(error)
  }
}

impl From<DocumentError> for FlowyError {
  fn from(error: DocumentError) -> Self {
    FlowyError::internal().with_context(error)
  }
}
