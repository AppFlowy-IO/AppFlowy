use std::str::FromStr;

use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_storage::{FileStorageService, StorageObject};
use lib_infra::future::FutureResult;
use tokio::io::AsyncReadExt;

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
  fn create_object(&self, object: StorageObject) -> FutureResult<String, FlowyError> {
    let try_get_client = self.client.try_get_client();
    let mime = mime::Mime::from_str(object.value.mime_type().as_str()).unwrap();
    let name = object.file_name.clone();

    FutureResult::new(async move {
      match object.value {
        flowy_storage::ObjectValue::File { file_path } => {
          let mut file = tokio::fs::File::open(file_path).await?;
          let mut buffer = Vec::new();
          let _n = file.read_to_end(&mut buffer).await?;
          try_get_client?
            .put_file_storage_object(&name, buffer.into(), &mime)
            .await?;
        },
        flowy_storage::ObjectValue::Bytes { bytes, .. } => {
          try_get_client?
            .put_file_storage_object(&name, bytes, &mime)
            .await?;
        },
      }
      Ok(name)
    })
  }

  fn delete_object_by_url(&self, object_url: String) -> FutureResult<(), FlowyError> {
    let try_get_client = self.client.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .delete_file_storage_object(&object_url)
        .await?;
      Ok(())
    })
  }

  fn get_object_by_url(&self, object_url: String) -> FutureResult<Bytes, FlowyError> {
    let try_get_client = self.client.try_get_client();
    FutureResult::new(async move {
      let data = try_get_client?.get_file_storage_object(&object_url).await?;
      Ok(data)
    })
  }
}
