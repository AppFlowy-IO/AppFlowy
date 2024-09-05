use crate::sqlite_sql::UploadFileTable;
use crate::uploader::UploadTask::BackgroundTask;
use flowy_storage_pub::chunked_byte::ChunkedBytes;
use flowy_storage_pub::storage::StorageService;
use lib_infra::box_any::BoxAny;
use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::fmt::Display;
use std::sync::atomic::{AtomicBool, AtomicU8};
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tracing::{error, info, trace};

#[derive(Clone)]
pub enum Signal {
  Stop,
  Proceed,
  ProceedAfterSecs(u64),
}

pub struct UploadTaskQueue {
  tasks: RwLock<BinaryHeap<UploadTask>>,
  notifier: watch::Sender<Signal>,
}

impl UploadTaskQueue {
  pub fn new(notifier: watch::Sender<Signal>) -> Self {
    Self {
      tasks: Default::default(),
      notifier,
    }
  }
  pub async fn queue_task(&self, task: UploadTask) {
    trace!("[File] Queued task: {}", task);
    self.tasks.write().await.push(task);
    let _ = self.notifier.send(Signal::Proceed);
  }
}

pub struct FileUploader {
  storage_service: Arc<dyn StorageService>,
  queue: Arc<UploadTaskQueue>,
  max_uploads: u8,
  current_uploads: AtomicU8,
  pause_sync: AtomicBool,
  has_exceeded_limit: Arc<AtomicBool>,
}

impl Drop for FileUploader {
  fn drop(&mut self) {
    let _ = self.queue.notifier.send(Signal::Stop);
  }
}

impl FileUploader {
  pub fn new(
    storage_service: Arc<dyn StorageService>,
    queue: Arc<UploadTaskQueue>,
    is_exceed_limit: Arc<AtomicBool>,
  ) -> Self {
    Self {
      storage_service,
      queue,
      max_uploads: 3,
      current_uploads: Default::default(),
      pause_sync: Default::default(),
      has_exceeded_limit: is_exceed_limit,
    }
  }

  pub async fn queue_tasks(&self, tasks: Vec<UploadTask>) {
    let mut queue_lock = self.queue.tasks.write().await;
    for task in tasks {
      queue_lock.push(task);
    }
    let _ = self.queue.notifier.send(Signal::Proceed);
  }

  pub fn pause(&self) {
    self
      .pause_sync
      .store(true, std::sync::atomic::Ordering::SeqCst);
  }

  pub fn disable_storage_write(&self) {
    self
      .has_exceeded_limit
      .store(true, std::sync::atomic::Ordering::SeqCst);
    self.pause();
  }

  pub fn enable_storage_write(&self) {
    self
      .has_exceeded_limit
      .store(false, std::sync::atomic::Ordering::SeqCst);
    self.resume();
  }

  pub fn resume(&self) {
    self
      .pause_sync
      .store(false, std::sync::atomic::Ordering::SeqCst);
    let _ = self.queue.notifier.send(Signal::ProceedAfterSecs(3));
  }

  pub async fn process_next(&self) -> Option<()> {
    // Do not proceed if the uploader is paused.
    if self.pause_sync.load(std::sync::atomic::Ordering::Relaxed) {
      info!("[File] Uploader is paused");
      return None;
    }

    let current_uploads = self
      .current_uploads
      .load(std::sync::atomic::Ordering::SeqCst);
    if current_uploads > 0 {
      trace!("[File] current upload tasks: {}", current_uploads)
    }

    if self
      .current_uploads
      .load(std::sync::atomic::Ordering::SeqCst)
      >= self.max_uploads
    {
      // If the current uploads count is greater than or equal to the max uploads, do not proceed.
      let _ = self.queue.notifier.send(Signal::ProceedAfterSecs(10));
      return None;
    }

    if self
      .has_exceeded_limit
      .load(std::sync::atomic::Ordering::SeqCst)
    {
      // If the storage limitation is enabled, do not proceed.
      return None;
    }

    let task = self.queue.tasks.write().await.pop()?;
    if task.retry_count() > 5 {
      // If the task has been retried more than 5 times, we should not retry it anymore.
      let _ = self.queue.notifier.send(Signal::ProceedAfterSecs(2));
      return None;
    }

    // increment the current uploads count
    self
      .current_uploads
      .fetch_add(1, std::sync::atomic::Ordering::SeqCst);

    match task {
      UploadTask::ImmediateTask {
        chunks,
        record,
        mut retry_count,
      }
      | UploadTask::Task {
        chunks,
        record,
        mut retry_count,
      } => {
        let record = BoxAny::new(record);
        if let Err(err) = self
          .storage_service
          .start_upload(chunks.clone(), &record)
          .await
        {
          if err.is_file_limit_exceeded() {
            error!("Failed to upload file: {}", err);
            self.disable_storage_write();
          }

          info!(
            "Failed to upload file: {}, retry_count:{}",
            err, retry_count
          );

          let record = record.unbox_or_error().unwrap();
          retry_count += 1;
          self.queue.tasks.write().await.push(UploadTask::Task {
            chunks,
            record,
            retry_count,
          });
        }
      },
      UploadTask::BackgroundTask {
        workspace_id,
        parent_dir,
        file_id,
        created_at,
        mut retry_count,
      } => {
        if let Err(err) = self
          .storage_service
          .resume_upload(&workspace_id, &parent_dir, &file_id)
          .await
        {
          if err.is_file_limit_exceeded() {
            error!("Failed to upload file: {}", err);
            self.disable_storage_write();
          }

          info!(
            "Failed to resume upload file: {}, retry_count:{}",
            err, retry_count
          );
          retry_count += 1;
          self.queue.tasks.write().await.push(BackgroundTask {
            workspace_id,
            parent_dir,
            file_id,
            created_at,
            retry_count,
          });
        }
      },
    }
    self
      .current_uploads
      .fetch_sub(1, std::sync::atomic::Ordering::SeqCst);
    let _ = self.queue.notifier.send(Signal::ProceedAfterSecs(2));
    None
  }
}

pub struct FileUploaderRunner;

impl FileUploaderRunner {
  pub async fn run(weak_uploader: Weak<FileUploader>, mut notifier: watch::Receiver<Signal>) {
    loop {
      // stops the runner if the notifier was closed.
      if notifier.changed().await.is_err() {
        info!("[File]:Uploader runner stopped, notifier closed");
        break;
      }

      if let Some(uploader) = weak_uploader.upgrade() {
        let value = notifier.borrow().clone();
        match value {
          Signal::Stop => {
            info!("[File]:Uploader runner stopped, stop signal received");
            break;
          },
          Signal::Proceed => {
            tokio::spawn(async move {
              uploader.process_next().await;
            });
          },
          Signal::ProceedAfterSecs(secs) => {
            tokio::time::sleep(Duration::from_secs(secs)).await;
            tokio::spawn(async move {
              uploader.process_next().await;
            });
          },
        }
      } else {
        info!("[File]:Uploader runner stopped, uploader dropped");
        break;
      }
    }
  }
}

pub enum UploadTask {
  ImmediateTask {
    chunks: ChunkedBytes,
    record: UploadFileTable,
    retry_count: u8,
  },
  Task {
    chunks: ChunkedBytes,
    record: UploadFileTable,
    retry_count: u8,
  },
  BackgroundTask {
    workspace_id: String,
    file_id: String,
    parent_dir: String,
    created_at: i64,
    retry_count: u8,
  },
}

impl UploadTask {
  pub fn retry_count(&self) -> u8 {
    match self {
      UploadTask::ImmediateTask { retry_count, .. } => *retry_count,
      UploadTask::Task { retry_count, .. } => *retry_count,
      UploadTask::BackgroundTask { retry_count, .. } => *retry_count,
    }
  }
}

impl Display for UploadTask {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      UploadTask::Task { record, .. } => write!(f, "Task: {}", record.file_id),
      UploadTask::BackgroundTask { file_id, .. } => write!(f, "BackgroundTask: {}", file_id),
      UploadTask::ImmediateTask { record, .. } => write!(f, "Immediate Task: {}", record.file_id),
    }
  }
}

impl Eq for UploadTask {}

impl PartialEq for UploadTask {
  fn eq(&self, other: &Self) -> bool {
    match (self, other) {
      (Self::ImmediateTask { record: lhs, .. }, Self::ImmediateTask { record: rhs, .. }) => {
        lhs.local_file_path == rhs.local_file_path
      },
      (Self::Task { record: lhs, .. }, Self::Task { record: rhs, .. }) => {
        lhs.local_file_path == rhs.local_file_path
      },
      (
        Self::BackgroundTask {
          workspace_id: l_workspace_id,
          file_id: l_file_id,
          ..
        },
        Self::BackgroundTask {
          workspace_id: r_workspace_id,
          file_id: r_file_id,
          ..
        },
      ) => l_workspace_id == r_workspace_id && l_file_id == r_file_id,
      _ => false,
    }
  }
}

impl PartialOrd for UploadTask {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
    Some(self.cmp(other))
  }
}

impl Ord for UploadTask {
  fn cmp(&self, other: &Self) -> Ordering {
    match (self, other) {
      (Self::ImmediateTask { record: lhs, .. }, Self::ImmediateTask { record: rhs, .. }) => {
        lhs.created_at.cmp(&rhs.created_at)
      },
      (_, Self::ImmediateTask { .. }) => Ordering::Less,
      (Self::ImmediateTask { .. }, _) => Ordering::Greater,
      (Self::Task { record: lhs, .. }, Self::Task { record: rhs, .. }) => {
        lhs.created_at.cmp(&rhs.created_at)
      },
      (_, Self::Task { .. }) => Ordering::Less,
      (Self::Task { .. }, _) => Ordering::Greater,
      (
        Self::BackgroundTask {
          created_at: lhs, ..
        },
        Self::BackgroundTask {
          created_at: rhs, ..
        },
      ) => lhs.cmp(rhs),
    }
  }
}
