use std::fmt;
use std::fmt::Debug;
use strum_macros::Display;

macro_rules! static_error {
  ($name:ident, $status:expr) => {
    #[allow(non_snake_case, missing_docs)]
    pub fn $name() -> SyncError {
      SyncError {
        code: $status,
        msg: format!("{}", $status),
      }
    }
  };
}

pub type SyncResult<T> = std::result::Result<T, SyncError>;

#[derive(Debug, Clone)]
pub struct SyncError {
  pub code: ErrorCode,
  pub msg: String,
}

impl SyncError {
  fn new(code: ErrorCode, msg: &str) -> Self {
    Self {
      code,
      msg: msg.to_owned(),
    }
  }

  pub fn context<T: Debug>(mut self, error: T) -> Self {
    self.msg = format!("{:?}", error);
    self
  }

  static_error!(serde, ErrorCode::SerdeError);
  static_error!(internal, ErrorCode::InternalError);
  static_error!(undo, ErrorCode::UndoFail);
  static_error!(redo, ErrorCode::RedoFail);
  static_error!(out_of_bound, ErrorCode::OutOfBound);
  static_error!(record_not_found, ErrorCode::RecordNotFound);
  static_error!(revision_conflict, ErrorCode::RevisionConflict);
  static_error!(
    can_not_delete_primary_field,
    ErrorCode::CannotDeleteThePrimaryField
  );
  static_error!(
    unexpected_empty_revision,
    ErrorCode::UnexpectedEmptyRevision
  );
}

impl fmt::Display for SyncError {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(f, "{:?}: {}", &self.code, &self.msg)
  }
}

#[derive(Debug, Clone, Display, PartialEq, Eq)]
pub enum ErrorCode {
  DocumentIdInvalid = 0,
  DocumentNotfound = 1,
  UndoFail = 200,
  RedoFail = 201,
  OutOfBound = 202,
  RevisionConflict = 203,
  RecordNotFound = 300,
  CannotDeleteThePrimaryField = 301,
  UnexpectedEmptyRevision = 302,
  SerdeError = 999,
  InternalError = 1000,
}

impl std::convert::From<lib_ot::errors::OTError> for SyncError {
  fn from(error: lib_ot::errors::OTError) -> Self {
    SyncError::new(ErrorCode::InternalError, "").context(error)
  }
}

// impl std::convert::From<protobuf::ProtobufError> for SyncError {
//     fn from(e: protobuf::ProtobufError) -> Self {
//         SyncError::internal().context(e)
//     }
// }

pub fn internal_sync_error<T>(e: T) -> SyncError
where
  T: std::fmt::Debug,
{
  SyncError::internal().context(e)
}
