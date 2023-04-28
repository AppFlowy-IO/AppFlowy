use crate::FlowyError;
use collab_database::error::DatabaseError;

impl From<DatabaseError> for FlowyError {
  fn from(error: DatabaseError) -> Self {
    FlowyError::internal().context(error)
  }
}
