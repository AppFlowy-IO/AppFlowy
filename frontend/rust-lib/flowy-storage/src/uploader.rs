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
use tracing::{debug, trace};

#[derive(Clone)]
pub enum Signal {
  Stop,
  Proceed,
  ProceedAfterMillis(u64),
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
  max_concurrent_uploads: u8,
  current_uploads: AtomicU8,
  pause_sync: AtomicBool,
}

impl Drop for FileUploader {
  fn drop(&mut self) {
    let _ = self.queue.notifier.send(Signal::Stop);
  }
}

impl FileUploader {
  pub fn new(storage_service: Arc<dyn StorageService>, queue: Arc<UploadTaskQueue>) -> Self {
    Self {
      storage_service,
      queue,
      max_concurrent_uploads: 3,
      current_uploads: Default::default(),
      pause_sync: Default::default(),
    }
  }

  pub async fn queue_tasks(&self, tasks: Vec<UploadTask>) {
    let mut queue_lock = self.queue.tasks.write().await;
    for task in tasks {
      queue_lock.push(task);
    }
    let _ = self.queue.notifier.send(Signal::Proceed);
  }

  pub async fn pause(&self) {
    self
      .pause_sync
      .store(true, std::sync::atomic::Ordering::SeqCst);
  }

  pub async fn resume(&self) {
    self
      .pause_sync
      .store(false, std::sync::atomic::Ordering::SeqCst);
    let _ = self.queue.notifier.send(Signal::Proceed);
  }

  pub async fn process_next(&self) -> Option<()> {
    // Do not proceed if the uploader is paused.
    if self.pause_sync.load(std::sync::atomic::Ordering::Relaxed) {
      return None;
    }

    let current_uploads = self
      .current_uploads
      .load(std::sync::atomic::Ordering::SeqCst);
    if current_uploads >= self.max_concurrent_uploads {
      return None;
    }

    self
      .current_uploads
      .fetch_add(1, std::sync::atomic::Ordering::SeqCst);
    let task = self.queue.tasks.write().await.pop()?;
    match task {
      UploadTask::Task { chunks, record } => {
        let record = BoxAny::new(record);
        let result = self.storage_service.start_upload(&chunks, &record).await;
        match result {
          Ok(_) => {},
          Err(_) => {
            let record = record.unbox_or_error().unwrap();
            self
              .queue
              .tasks
              .write()
              .await
              .push(UploadTask::Task { chunks, record });
          },
        }
      },
      UploadTask::BackgroundTask {
        workspace_id,
        parent_dir,
        file_id,
        created_at,
      } => {
        let result = self
          .storage_service
          .resume_upload(&workspace_id, &parent_dir, &file_id)
          .await;
        match result {
          Ok(_) => debug!("Resumed upload for file: {}", file_id),
          Err(_) => {
            self.queue.tasks.write().await.push(BackgroundTask {
              workspace_id,
              parent_dir,
              file_id,
              created_at,
            });
          },
        }
      },
    }
    self
      .current_uploads
      .fetch_sub(1, std::sync::atomic::Ordering::SeqCst);
    let _ = self.queue.notifier.send(Signal::ProceedAfterMillis(2000));
    None
  }
}

pub struct FileUploaderRunner;

impl FileUploaderRunner {
  pub async fn run(weak_uploader: Weak<FileUploader>, mut notifier: watch::Receiver<Signal>) {
    loop {
      // stops the runner if the notifier was closed.
      if notifier.changed().await.is_err() {
        break;
      }

      if let Some(uploader) = weak_uploader.upgrade() {
        let value = notifier.borrow().clone();
        match value {
          Signal::Stop => break,
          Signal::Proceed => {
            uploader.process_next().await;
          },
          Signal::ProceedAfterMillis(millis) => {
            tokio::time::sleep(Duration::from_millis(millis)).await;
            uploader.process_next().await;
          },
        }
      } else {
        break;
      }
    }
  }
}

pub enum UploadTask {
  Task {
    chunks: ChunkedBytes,
    record: UploadFileTable,
  },
  BackgroundTask {
    workspace_id: String,
    file_id: String,
    parent_dir: String,
    created_at: i64,
  },
}

impl Display for UploadTask {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      Self::Task { record, .. } => write!(f, "Task: {}", record.local_file_path),
      Self::BackgroundTask { file_id, .. } => write!(f, "BackgroundTask: {}", file_id),
    }
  }
}

impl UploadTask {}

impl Eq for UploadTask {}

impl PartialEq for UploadTask {
  fn eq(&self, other: &Self) -> bool {
    match (self, other) {
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
