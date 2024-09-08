use crate::af_cloud::AFServer;
use client_api::entity::{CompleteUploadRequest, CreateUploadRequest};
use flowy_error::FlowyError;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use lib_infra::async_trait::async_trait;

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
  async fn get_object_url(&self, object_id: ObjectIdentity) -> Result<String, FlowyError> {
    let file_name = format!("{}.{}", object_id.file_id, object_id.ext);
    let url = self
      .0
      .try_get_client()?
      .get_blob_url(&object_id.workspace_id, &file_name);
    Ok(url)
  }

  async fn put_object(&self, url: String, file: ObjectValue) -> Result<(), FlowyError> {
    let client = self.0.try_get_client()?;
    client.put_blob(&url, file.raw, &file.mime).await?;
    Ok(())
  }

  async fn delete_object(&self, url: &str) -> Result<(), FlowyError> {
    self.0.try_get_client()?.delete_blob(url).await?;
    Ok(())
  }

  async fn get_object(&self, url: String) -> Result<ObjectValue, FlowyError> {
    let (mime, raw) = self.0.try_get_client()?.get_blob(&url).await?;
    Ok(ObjectValue {
      raw: raw.into(),
      mime,
    })
  }

  async fn get_object_url_v1(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> Result<String, FlowyError> {
    let url = self
      .0
      .try_get_client()?
      .get_blob_url_v1(workspace_id, parent_dir, file_id);
    Ok(url)
  }

  async fn parse_object_url_v1(&self, url: &str) -> Option<(String, String, String)> {
    let value = self.0.try_get_client().ok()?.parse_blob_url_v1(url)?;
    Some(value)
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
