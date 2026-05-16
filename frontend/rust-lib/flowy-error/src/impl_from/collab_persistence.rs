use crate::{ErrorCode, FlowyError};
#[cfg(feature = "impl_from_collab_persistence")]
use collab_plugins::local_storage::kv::PersistenceError;

#[cfg(feature = "impl_from_collab_persistence")]
impl From<PersistenceError> for FlowyError {
  fn from(err: PersistenceError) -> Self {
    match err {
      PersistenceError::UnexpectedEmptyUpdates => FlowyError::new(ErrorCode::RecordNotFound, err),
      #[cfg(not(target_arch = "wasm32"))]
      PersistenceError::RocksdbCorruption(_) => FlowyError::new(ErrorCode::RocksdbCorruption, err),
      #[cfg(not(target_arch = "wasm32"))]
      PersistenceError::RocksdbIOError(_) => FlowyError::new(ErrorCode::RocksdbIOError, err),
      _ => FlowyError::new(ErrorCode::RocksdbInternal, err),
    }
  }
}
