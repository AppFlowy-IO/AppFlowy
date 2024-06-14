use crate::object_from_disk;
use flowy_error::{FlowyError, FlowyResult};
use flowy_storage_pub::cloud::ObjectStorageCloudService;
use flowy_storage_pub::storage::StorageService;
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::io::AsyncWriteExt;
use tracing::{debug, error, info};

pub struct StorageManager {
  cloud_service: Arc<dyn ObjectStorageCloudService>,
}

impl StorageManager {
  pub fn new(cloud_service: Arc<dyn ObjectStorageCloudService>) -> Self {
    Self { cloud_service }
  }
}

impl StorageService for StorageManager {
  fn upload_object(
    &self,
    workspace_id: &str,
    local_file_path: &str,
  ) -> FutureResult<String, FlowyError> {
    let cloud_service = self.cloud_service.clone();
    let workspace_id = workspace_id.to_string();
    let local_file_path = local_file_path.to_string();
    FutureResult::new(async move {
      let (object_identity, object_value) =
        object_from_disk(&workspace_id, &local_file_path).await?;
      let url = cloud_service.get_object_url(object_identity).await?;
      match cloud_service.put_object(url.clone(), object_value).await {
        Ok(_) => {
          debug!("[File] success uploaded file to cloud: {}", url);
        },
        Err(err) => {
          error!("[File] upload file failed: {}", err);
          return Err(err);
        },
      }
      Ok(url)
    })
  }

  fn delete_object(&self, url: String, local_file_path: String) -> FlowyResult<()> {
    let cloud_service = self.cloud_service.clone();
    tokio::spawn(async move {
      match tokio::fs::remove_file(&local_file_path).await {
        Ok(_) => {
          debug!("[File] deleted file from local disk: {}", local_file_path)
        },
        Err(err) => {
          error!("[File] delete file at {} failed: {}", local_file_path, err);
        },
      }
      if let Err(e) = cloud_service.delete_object(&url).await {
        // TODO: add WAL to log the delete operation.
        // keep a list of files to be deleted, and retry later
        error!("[File] delete file failed: {}", e);
      }
      debug!("[File] deleted file from cloud: {}", url);
    });
    Ok(())
  }

  fn download_object(&self, url: String, local_file_path: String) -> FlowyResult<()> {
    let cloud_service = self.cloud_service.clone();
    tokio::spawn(async move {
      if tokio::fs::metadata(&local_file_path).await.is_ok() {
        tracing::warn!("file already exist in user local disk: {}", local_file_path);
        return Ok(());
      }
      let object_value = cloud_service.get_object(url).await?;
      let mut file = tokio::fs::OpenOptions::new()
        .create(true)
        .truncate(true)
        .write(true)
        .open(&local_file_path)
        .await?;

      match file.write(&object_value.raw).await {
        Ok(n) => {
          info!("downloaded {} bytes to file: {}", n, local_file_path);
        },
        Err(err) => {
          error!("write file failed: {}", err);
        },
      }
      Ok::<_, FlowyError>(())
    });
    Ok(())
  }
}
