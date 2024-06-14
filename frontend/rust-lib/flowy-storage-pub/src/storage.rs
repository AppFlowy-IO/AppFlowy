use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::FutureResult;

pub trait StorageService: Send + Sync {
  fn upload_object(
    &self,
    workspace_id: &str,
    local_file_path: &str,
  ) -> FutureResult<String, FlowyError>;

  fn delete_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;

  fn download_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;
}
