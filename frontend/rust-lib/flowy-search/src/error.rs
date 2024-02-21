use flowy_error::{ErrorCode, FlowyError};
use tantivy::TantivyError;

trait ConvertToFlowyError {
  fn convert_to_flowy_error(self) -> FlowyError;
}

impl ConvertToFlowyError for TantivyError {
  fn convert_to_flowy_error(self) -> FlowyError {
    FlowyError::new(ErrorCode::IndexWriterFailedCommit, self)
  }
}
