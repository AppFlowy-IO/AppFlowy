use crate::chunked_byte::ChunkedBytes;
use async_trait::async_trait;
pub use client_api_entity::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

#[async_trait]
pub trait StorageService: Send + Sync {
  fn upload_object(
    &self,
    workspace_id: &str,
    local_file_path: &str,
  ) -> FutureResult<String, FlowyError>;

  fn delete_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;

  fn download_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;

  fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    local_file_path: &str,
  ) -> FutureResult<String, FlowyError>;

  async fn start_upload(&self, chunks: &ChunkedBytes, record: &BoxAny) -> Result<(), FlowyError>;

  async fn resume_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> Result<(), FlowyError>;
}
