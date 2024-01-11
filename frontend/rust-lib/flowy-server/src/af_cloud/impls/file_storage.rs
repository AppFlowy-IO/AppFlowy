use bytes::Bytes;

use flowy_error::FlowyError;
use flowy_storage::{FileStorageService, StorageObject};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub struct AFCloudFileStorageServiceImpl<T>(pub T);

impl<T> AFCloudFileStorageServiceImpl<T> {
  pub fn new(client: T) -> Self {
    Self(client)
  }
}

impl<T> FileStorageService for AFCloudFileStorageServiceImpl<T>
where
  T: AFServer,
{
  fn create_object(&self, _object: StorageObject) -> FutureResult<String, FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }

  fn delete_object_by_url(&self, _object_url: String) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }

  fn get_object_by_url(&self, _object_url: String) -> FutureResult<Bytes, FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }
}
