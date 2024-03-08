use crate::FlowyError;
#[cfg(feature = "impl_from_collab_database")]
use collab_database::error::DatabaseError;

#[cfg(feature = "impl_from_collab_document")]
use collab_document::error::DocumentError;

#[cfg(feature = "impl_from_collab_database")]
impl From<DatabaseError> for FlowyError {
  fn from(error: DatabaseError) -> Self {
    FlowyError::internal().with_context(error)
  }
}

#[cfg(feature = "impl_from_collab_document")]
impl From<DocumentError> for FlowyError {
  fn from(error: DocumentError) -> Self {
    match error {
      DocumentError::NoRequiredData => FlowyError::invalid_data().with_context(error),
      _ => FlowyError::internal().with_context(error),
    }
  }
}

#[cfg(feature = "impl_from_collab_folder")]
use collab_folder::error::FolderError;

#[cfg(feature = "impl_from_collab_folder")]
impl From<FolderError> for FlowyError {
  fn from(error: FolderError) -> Self {
    match error {
      FolderError::NoRequiredData(_) => FlowyError::invalid_data().with_context(error),
      _ => FlowyError::internal().with_context(error),
    }
  }
}
