use client_api::entity::CreateUploadRequest;
use flowy_error::FlowyError;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub struct AFCloudFileStorageServiceImpl<T>(pub T);

impl<T> AFCloudFileStorageServiceImpl<T> {
  pub fn new(client: T) -> Self {
    Self(client)
  }
}

impl<T> StorageCloudService for AFCloudFileStorageServiceImpl<T>
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

  fn delete_object(&self, url: &str) -> FutureResult<(), FlowyError> {
    let url = url.to_string();
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

  fn create_upload(
    &self,
    workspace_id: &str,
    file_id: &str,
    parent_dir: &str,
    content_type: &str,
  ) -> FutureResult<CreateUploadResponse, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let parent_dir = parent_dir.to_string();
    let content_type = content_type.to_string();
    let file_id = file_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let req = CreateUploadRequest {
        file_id,
        parent_dir,
        content_type,
      };
      let resp = client.create_upload(&workspace_id, req).await?;
      Ok(resp)
    })
  }

  fn upload_part(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    part_number: i32,
    body: Vec<u8>,
  ) -> FutureResult<UploadPartResponse, FlowyError> {
    todo!()
  }

  fn complete_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    parts: Vec<CompletedPartRequest>,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }
}
