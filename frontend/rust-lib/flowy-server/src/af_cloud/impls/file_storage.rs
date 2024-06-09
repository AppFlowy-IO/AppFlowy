use flowy_error::FlowyError;
use flowy_storage::{ObjectIdentity, ObjectStorageService, ObjectValue};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub struct AFCloudFileStorageServiceImpl<T>(pub T);

impl<T> AFCloudFileStorageServiceImpl<T> {
  pub fn new(client: T) -> Self {
    Self(client)
  }
}

impl<T> ObjectStorageService for AFCloudFileStorageServiceImpl<T>
where
  T: AFServer,
{
  fn get_object_url(&self, object_id: ObjectIdentity) -> FutureResult<String, FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let file_name = format!("{}.{}", object_id.file_id, object_id.ext);
      let client = try_get_client?;
      let url = client.get_blob_url(&object_id.workspace_id, &file_name);
      Ok(url)
    })
  }

  fn put_object(&self, url: String, file: ObjectValue) -> FutureResult<(), FlowyError> {
    let try_get_client = self.0.try_get_client();
    let file = file.clone();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.put_blob(&url, file.raw, &file.mime).await?;
      Ok(())
    })
  }

  fn delete_object(&self, url: String) -> FutureResult<(), FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      client.delete_blob(&url).await?;
      Ok(())
    })
  }

  fn get_object(&self, url: String) -> FutureResult<ObjectValue, FlowyError> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let (mime, raw) = client.get_blob(&url).await?;
      Ok(ObjectValue {
        raw: raw.into(),
        mime,
      })
    })
  }
}
