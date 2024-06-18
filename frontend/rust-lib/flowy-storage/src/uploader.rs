use flowy_storage_pub::storage::StorageService;
use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::sync::atomic::{AtomicBool, AtomicU8};
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::sync::{watch, RwLock};
use tracing::debug;

#[derive(Clone)]
pub enum Signal {
  Stop,
  Proceed,
  ProceedAfterMillis(u64),
}

pub struct FileUploader {
  notifier: watch::Sender<Signal>,
  storage_service: Arc<dyn StorageService>,
  queue: RwLock<BinaryHeap<UploadTask>>,
  max_concurrent_uploads: u8,
  current_uploads: AtomicU8,
  pause_sync: AtomicBool,
}

impl Drop for FileUploader {
  fn drop(&mut self) {
    let _ = self.notifier.send(Signal::Stop);
  }
}

impl FileUploader {
  pub fn new(storage_service: Arc<dyn StorageService>, notifier: watch::Sender<Signal>) -> Self {
    Self {
      storage_service,
      notifier,
      queue: Default::default(),
      max_concurrent_uploads: 3,
      current_uploads: Default::default(),
      pause_sync: Default::default(),
    }
  }

  pub async fn queue_task(&self, task: UploadTask) {
    self.queue.write().await.push(task);
    let _ = self.notifier.send(Signal::Proceed);
  }

  pub async fn queue_tasks(&self, tasks: Vec<UploadTask>) {
    let mut queue_lock = self.queue.write().await;
    for task in tasks {
      queue_lock.push(task);
    }
    let _ = self.notifier.send(Signal::Proceed);
  }

  pub async fn clear(&self) {
    self.queue.write().await.clear();
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
    let _ = self.notifier.send(Signal::Proceed);
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
    let task = self.queue.write().await.pop()?;
    match &task {
      UploadTask::Task {
        local_file_path,
        workspace_id,
        parent_dir,
        ..
      } => {
        let result = self
          .storage_service
          .create_upload(workspace_id, parent_dir, local_file_path)
          .await;
        match result {
          Ok(_) => debug!("Uploaded file: {}", local_file_path),
          Err(_) => {
            self.queue.write().await.push(task);
          },
        }
      },
      UploadTask::BackgroundTask {
        workspace_id,
        parent_dir,
        file_id,
        ..
      } => {
        let result = self
          .storage_service
          .resume_upload(workspace_id, parent_dir, file_id)
          .await;
        match result {
          Ok(_) => debug!("Resumed upload for file: {}", file_id),
          Err(_) => {
            self.queue.write().await.push(task);
          },
        }
      },
    }
    self
      .current_uploads
      .fetch_sub(1, std::sync::atomic::Ordering::SeqCst);
    let _ = self.notifier.send(Signal::ProceedAfterMillis(2000));
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
    local_file_path: String,
    workspace_id: String,
    parent_dir: String,
    created_at: i64,
  },
  BackgroundTask {
    workspace_id: String,
    file_id: String,
    parent_dir: String,
    created_at: i64,
  },
}

impl UploadTask {}

impl Eq for UploadTask {}

impl PartialEq for UploadTask {
  fn eq(&self, other: &Self) -> bool {
    match (self, other) {
      (
        Self::Task {
          local_file_path: lhs,
          ..
        },
        Self::Task {
          local_file_path: rhs,
          ..
        },
      ) => lhs == rhs,
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
      (
        Self::Task {
          created_at: lhs, ..
        },
        Self::Task {
          created_at: rhs, ..
        },
      ) => lhs.cmp(rhs),
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
