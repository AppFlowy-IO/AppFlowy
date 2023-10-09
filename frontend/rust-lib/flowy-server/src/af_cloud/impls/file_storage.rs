use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_storage::{FileStorageService, StorageObject};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub struct AFCloudFileStorageServiceImpl<T> {
  #[allow(dead_code)]
  client: T,
}

impl<T> AFCloudFileStorageServiceImpl<T> {
  pub fn new(client: T) -> Self {
    Self { client }
  }
}

impl<T> FileStorageService for AFCloudFileStorageServiceImpl<T>
where
  T: AFServer,
{
  fn create_object(&self, _object: StorageObject) -> FutureResult<String, FlowyError> {
    FutureResult::new(async move {
      // TODO
      Ok("".to_owned())
    })
  }

  fn delete_object_by_url(&self, _object_url: String) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move {
      // TODO
      Ok(())
    })
  }

  fn get_object_by_url(&self, _object_url: String) -> FutureResult<Bytes, FlowyError> {
    FutureResult::new(async move {
      // TODO
      Ok(Bytes::new())
    })
  }
}
