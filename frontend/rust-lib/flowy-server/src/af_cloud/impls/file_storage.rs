use bytes::Bytes;
use tokio::fs::File;
use tokio::io::AsyncReadExt;

use flowy_error::FlowyError;
use flowy_storage::{FileStorageService, ObjectValue, StorageObject};
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
  fn create_object(&self, object: StorageObject) -> FutureResult<String, FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;

      match object.value {
        ObjectValue::File { file_path } => {
          let mut file = File::open(&file_path).await?;
          let mime = mime_guess::from_path(file_path)
            .first_or_octet_stream()
            .to_string();
          let mut buffer = Vec::new();
          file.read_to_end(&mut buffer).await?;
          Ok(client.put_blob(&object.workspace_id, buffer, mime).await?)
        },
        ObjectValue::Bytes { bytes, mime } => {
          Ok(client.put_blob(&object.workspace_id, bytes, mime).await?)
        },
      }
    })
  }

  fn delete_object_by_url(&self, object_url: String) -> FutureResult<(), FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.delete_blob(&object_url).await?;
      Ok(())
    })
  }

  fn get_object_by_url(&self, object_url: String) -> FutureResult<Bytes, FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let bytes = client.get_blob(&object_url).await?;
      Ok(bytes)
    })
  }
}
