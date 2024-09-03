use crate::chunked_byte::ChunkedBytes;
use async_trait::async_trait;
pub use client_api_entity::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;
use serde::Serialize;
use std::fmt::Display;
use std::ops::{Deref, DerefMut};
use tokio::sync::broadcast;
use tracing::error;

#[async_trait]
pub trait StorageService: Send + Sync {
  fn delete_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;

  fn download_object(&self, url: String, local_file_path: String) -> FlowyResult<()>;

  async fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    local_file_path: &str,
    upload_immediately: bool,
  ) -> Result<(CreatedUpload, Option<FileProgressReceiver>), FlowyError>;

  async fn start_upload(&self, chunks: ChunkedBytes, record: &BoxAny) -> Result<(), FlowyError>;

  async fn resume_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> Result<(), FlowyError>;

  async fn subscribe_file_progress(
    &self,
    parent_idr: &str,
    file_id: &str,
  ) -> Result<Option<FileProgressReceiver>, FlowyError>;
}

pub struct FileProgressReceiver {
  pub rx: broadcast::Receiver<FileUploadState>,
  pub file_id: String,
}

impl Deref for FileProgressReceiver {
  type Target = broadcast::Receiver<FileUploadState>;

  fn deref(&self) -> &Self::Target {
    &self.rx
  }
}

impl DerefMut for FileProgressReceiver {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.rx
  }
}

#[derive(Clone, Debug)]
pub enum FileUploadState {
  NotStarted,
  Uploading { progress: f64 },
  Finished { file_id: String },
}

#[derive(Clone, Debug, Serialize)]
pub struct FileProgress {
  pub file_id: String,
  pub progress: f64,
  pub error: Option<String>,
}

impl Display for FileProgress {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(f, "FileProgress: {} - {}", self.file_id, self.progress)
  }
}

#[derive(Debug)]
pub struct ProgressNotifier {
  file_id: String,
  tx: broadcast::Sender<FileUploadState>,
  pub current_value: Option<FileUploadState>,
}

impl ProgressNotifier {
  pub fn new(file_id: String) -> Self {
    let (tx, _) = broadcast::channel(100);
    ProgressNotifier {
      file_id,
      tx,
      current_value: None,
    }
  }

  pub fn subscribe(&self) -> FileProgressReceiver {
    FileProgressReceiver {
      rx: self.tx.subscribe(),
      file_id: self.file_id.clone(),
    }
  }

  pub async fn notify(&mut self, progress: FileUploadState) {
    self.current_value = Some(progress.clone());
    if let Err(err) = self.tx.send(progress) {
      error!("Failed to send progress notification: {:?}", err);
    }
  }
}

pub struct CreatedUpload {
  pub url: String,
  pub file_id: String,
}
