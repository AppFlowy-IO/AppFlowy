use client_api::entity::{CompleteUploadRequest, CreateUploadRequest};
use flowy_error::{FlowyError, FlowyResult};
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub struct AFCloudFileStorageServiceImpl<T>(pub T);

impl<T> AFCloudFileStorageServiceImpl<T> {
  pub fn new(client: T) -> Self {
    Self(client)
  }
}

#[async_trait]
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

  fn get_object_url_v1(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> FlowyResult<String> {
    let client = self.0.try_get_client()?;
    let url = client.get_blob_url_v1(workspace_id, parent_dir, file_id);
    Ok(url)
  }

  async fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
    content_type: &str,
  ) -> Result<CreateUploadResponse, FlowyError> {
    let parent_dir = parent_dir.to_string();
    let content_type = content_type.to_string();
    let file_id = file_id.to_string();
    let try_get_client = self.0.try_get_client();
    let client = try_get_client?;
    let req = CreateUploadRequest {
      file_id,
      parent_dir,
      content_type,
    };
    let resp = client.create_upload(workspace_id, req).await?;
    Ok(resp)
  }

  async fn upload_part(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    part_number: i32,
    body: Vec<u8>,
  ) -> Result<UploadPartResponse, FlowyError> {
    let try_get_client = self.0.try_get_client();
    let client = try_get_client?;
    let resp = client
      .upload_part(
        workspace_id,
        parent_dir,
        file_id,
        upload_id,
        part_number,
        body,
      )
      .await?;

    Ok(resp)
  }

  async fn complete_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    parts: Vec<CompletedPartRequest>,
  ) -> Result<(), FlowyError> {
    let parent_dir = parent_dir.to_string();
    let upload_id = upload_id.to_string();
    let file_id = file_id.to_string();
    let try_get_client = self.0.try_get_client();
    let client = try_get_client?;
    let request = CompleteUploadRequest {
      file_id,
      parent_dir,
      upload_id,
      parts,
    };
    client.complete_upload(workspace_id, request).await?;
    Ok(())
  }
}
