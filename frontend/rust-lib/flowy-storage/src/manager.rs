use crate::file_cache::FileTempStorage;
use crate::notification::{make_notification, StorageNotification};
use crate::sqlite_sql::{
  batch_select_upload_file, delete_upload_file, insert_upload_file, insert_upload_part,
  is_upload_completed, select_upload_file, select_upload_parts, update_upload_file_completed,
  update_upload_file_upload_id, UploadFilePartTable, UploadFileTable,
};
use crate::uploader::{FileUploader, FileUploaderRunner, Signal, UploadTask, UploadTaskQueue};
use allo_isolate::Isolate;
use async_trait::async_trait;
use dashmap::DashMap;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use flowy_storage_pub::chunked_byte::{ChunkedBytes, MIN_CHUNK_SIZE};
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{
  CompletedPartRequest, CreatedUpload, FileProgress, FileProgressReceiver, FileUploadState,
  ProgressNotifier, StorageService, UploadPartResponse,
};
use lib_infra::box_any::BoxAny;
use lib_infra::isolate_stream::{IsolateSink, SinkExt};
use lib_infra::util::timestamp;
use std::io::ErrorKind;
use std::path::{Path, PathBuf};
use std::sync::atomic::AtomicBool;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::{broadcast, watch};
use tracing::{debug, error, info, instrument, trace};

pub trait StorageUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn get_application_root_dir(&self) -> &str;
}

type GlobalNotifier = broadcast::Sender<FileProgress>;
pub struct StorageManager {
  pub storage_service: Arc<dyn StorageService>,
  uploader: Arc<FileUploader>,
  progress_notifiers: Arc<DashMap<String, ProgressNotifier>>,
  global_notifier: GlobalNotifier,
}

impl Drop for StorageManager {
  fn drop(&mut self) {
    info!("[File] StorageManager is dropped");
  }
}

impl StorageManager {
  pub fn new(
    cloud_service: Arc<dyn StorageCloudService>,
    user_service: Arc<dyn StorageUserService>,
  ) -> Self {
    let is_exceed_storage_limit = Arc::new(AtomicBool::new(false));
    let temp_storage_path = PathBuf::from(format!(
      "{}/cache_files",
      user_service.get_application_root_dir()
    ));
    let (global_notifier, _) = broadcast::channel(1000);
    let temp_storage = Arc::new(FileTempStorage::new(temp_storage_path));
    let (notifier, notifier_rx) = watch::channel(Signal::Proceed);
    let task_queue = Arc::new(UploadTaskQueue::new(notifier));
    let progress_notifiers = Arc::new(DashMap::new());
    let storage_service = Arc::new(StorageServiceImpl {
      cloud_service,
      user_service: user_service.clone(),
      temp_storage,
      task_queue: task_queue.clone(),
      is_exceed_storage_limit: is_exceed_storage_limit.clone(),
      progress_notifiers: progress_notifiers.clone(),
      global_notifier: global_notifier.clone(),
    });

    let uploader = Arc::new(FileUploader::new(
      storage_service.clone(),
      task_queue,
      is_exceed_storage_limit,
    ));
    tokio::spawn(FileUploaderRunner::run(
      Arc::downgrade(&uploader),
      notifier_rx,
    ));

    let weak_uploader = Arc::downgrade(&uploader);
    tokio::spawn(async move {
      // Start uploading after 20 seconds
      tokio::time::sleep(Duration::from_secs(20)).await;
      if let Some(uploader) = weak_uploader.upgrade() {
        if let Err(err) = prepare_upload_task(uploader, user_service).await {
          error!("prepare upload task failed: {}", err);
        }
      }
    });

    Self {
      storage_service,
      uploader,
      progress_notifiers,
      global_notifier,
    }
  }

  pub async fn register_file_progress_stream(&self, port: i64) {
    info!("register file progress stream: {}", port);
    let mut sink = IsolateSink::new(Isolate::new(port));
    let mut rx = self.global_notifier.subscribe();
    tokio::spawn(async move {
      while let Ok(progress) = rx.recv().await {
        if let Ok(s) = serde_json::to_string(&progress) {
          if let Err(err) = sink.send(s).await {
            error!("[File]: send file progress failed: {}", err);
          }
        }
      }
    });
  }

  pub async fn initialize(&self, _workspace_id: &str) {
    self.enable_storage_write_access();
  }

  pub fn update_network_reachable(&self, reachable: bool) {
    if reachable {
      self.uploader.resume();
    } else {
      self.uploader.pause();
    }
  }

  pub fn disable_storage_write_access(&self) {
    // when storage is purchased, resume the uploader
    self.uploader.disable_storage_write();
  }

  pub fn enable_storage_write_access(&self) {
    // when storage is purchased, resume the uploader
    self.uploader.enable_storage_write();
  }

  pub async fn subscribe_file_state(
    &self,
    parent_dir: &str,
    file_id: &str,
  ) -> Result<Option<FileProgressReceiver>, FlowyError> {
    self
      .storage_service
      .subscribe_file_progress(parent_dir, file_id)
      .await
  }

  pub async fn get_file_state(&self, file_id: &str) -> Option<FileUploadState> {
    self
      .progress_notifiers
      .get(file_id)
      .and_then(|notifier| notifier.value().current_value.clone())
  }
}

async fn prepare_upload_task(
  uploader: Arc<FileUploader>,
  user_service: Arc<dyn StorageUserService>,
) -> FlowyResult<()> {
  let uid = user_service.user_id()?;
  let conn = user_service.sqlite_connection(uid)?;
  let upload_files = batch_select_upload_file(conn, 100)?;
  let tasks = upload_files
    .into_iter()
    .map(|upload_file| UploadTask::BackgroundTask {
      workspace_id: upload_file.workspace_id,
      file_id: upload_file.file_id,
      parent_dir: upload_file.parent_dir,
      created_at: upload_file.created_at,
      retry_count: 0,
    })
    .collect::<Vec<_>>();
  info!("prepare upload task: {}", tasks.len());
  uploader.queue_tasks(tasks).await;
  Ok(())
}

pub struct StorageServiceImpl {
  cloud_service: Arc<dyn StorageCloudService>,
  user_service: Arc<dyn StorageUserService>,
  temp_storage: Arc<FileTempStorage>,
  task_queue: Arc<UploadTaskQueue>,
  is_exceed_storage_limit: Arc<AtomicBool>,
  progress_notifiers: Arc<DashMap<String, ProgressNotifier>>,
  global_notifier: GlobalNotifier,
}

#[async_trait]
impl StorageService for StorageServiceImpl {
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

  async fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_path: &str,
    upload_immediately: bool,
  ) -> Result<(CreatedUpload, Option<FileProgressReceiver>), FlowyError> {
    if workspace_id.is_empty() {
      return Err(FlowyError::internal().with_context("workspace id is empty"));
    }

    if parent_dir.is_empty() {
      return Err(FlowyError::internal().with_context("parent dir is empty"));
    }

    if file_path.is_empty() {
      return Err(FlowyError::internal().with_context("local file path is empty"));
    }

    let workspace_id = workspace_id.to_string();
    let parent_dir = parent_dir.to_string();
    let file_path = file_path.to_string();

    let is_exceed_limit = self
      .is_exceed_storage_limit
      .load(std::sync::atomic::Ordering::Relaxed);
    if is_exceed_limit {
      make_notification(StorageNotification::FileStorageLimitExceeded)
        .payload(FlowyError::file_storage_limit())
        .send();

      return Err(FlowyError::file_storage_limit());
    }

    let local_file_path = self
      .temp_storage
      .create_temp_file_from_existing(Path::new(&file_path))
      .await
      .map_err(|err| {
        error!("[File] create temp file failed: {}", err);
        FlowyError::internal()
          .with_context(format!("create temp file for upload file failed: {}", err))
      })?;

    // 1. create a file record and chunk the file
    let (chunks, record) = create_upload_record(workspace_id, parent_dir, local_file_path).await?;

    // 2. save the record to sqlite
    let conn = self
      .user_service
      .sqlite_connection(self.user_service.user_id()?)?;
    let url = self
      .cloud_service
      .get_object_url_v1(&record.workspace_id, &record.parent_dir, &record.file_id)
      .await?;
    let file_id = record.file_id.clone();
    match insert_upload_file(conn, &record) {
      Ok(_) => {
        // 3. generate url for given file
        if upload_immediately {
          self
            .task_queue
            .queue_task(UploadTask::ImmediateTask {
              chunks,
              record,
              retry_count: 3,
            })
            .await;
        } else {
          self
            .task_queue
            .queue_task(UploadTask::Task {
              chunks,
              record,
              retry_count: 0,
            })
            .await;
        }

        let notifier = ProgressNotifier::new(file_id.to_string());
        let receiver = notifier.subscribe();
        self
          .progress_notifiers
          .insert(file_id.to_string(), notifier);
        Ok::<_, FlowyError>((CreatedUpload { url, file_id }, Some(receiver)))
      },
      Err(err) => {
        if matches!(err.code, ErrorCode::DuplicateSqliteRecord) {
          info!("upload record already exists, skip creating new upload task");
          Ok::<_, FlowyError>((CreatedUpload { url, file_id }, None))
        } else {
          Err(err)
        }
      },
    }
  }

  async fn start_upload(&self, chunks: ChunkedBytes, record: &BoxAny) -> Result<(), FlowyError> {
    let file_record = record.downcast_ref::<UploadFileTable>().ok_or_else(|| {
      FlowyError::internal().with_context("failed to downcast record to UploadFileTable")
    })?;

    if let Err(err) = start_upload(
      &self.cloud_service,
      &self.user_service,
      &self.temp_storage,
      chunks,
      file_record,
      self.progress_notifiers.clone(),
      self.global_notifier.clone(),
    )
    .await
    {
      error!("[File] start upload failed: {}", err);
    }
    Ok(())
  }

  async fn resume_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> Result<(), FlowyError> {
    // Gathering the upload record and parts from the sqlite database.
    let mut conn = self
      .user_service
      .sqlite_connection(self.user_service.user_id()?)?;

    if let Some(upload_file) = select_upload_file(&mut conn, workspace_id, parent_dir, file_id)? {
      resume_upload(
        &self.cloud_service,
        &self.user_service,
        &self.temp_storage,
        upload_file,
        self.progress_notifiers.clone(),
        self.global_notifier.clone(),
      )
      .await?;
    } else {
      error!("[File] resume upload failed: record not found");
    }
    Ok(())
  }

  async fn subscribe_file_progress(
    &self,
    parent_idr: &str,
    file_id: &str,
  ) -> Result<Option<FileProgressReceiver>, FlowyError> {
    trace!("[File]: subscribe file progress: {}", file_id);

    let is_completed = {
      let mut conn = self
        .user_service
        .sqlite_connection(self.user_service.user_id()?)?;
      let workspace_id = self.user_service.workspace_id()?;
      is_upload_completed(&mut conn, &workspace_id, parent_idr, file_id).unwrap_or(false)
    };
    if is_completed {
      return Ok(None);
    }

    let notifier = self
      .progress_notifiers
      .entry(file_id.to_string())
      .or_insert_with(|| ProgressNotifier::new(file_id.to_string()));
    Ok(Some(notifier.subscribe()))
  }
}

async fn create_upload_record(
  workspace_id: String,
  parent_dir: String,
  local_file_path: String,
) -> FlowyResult<(ChunkedBytes, UploadFileTable)> {
  // read file and chunk it base on CHUNK_SIZE. We use MIN_CHUNK_SIZE as the minimum chunk size
  let chunked_bytes = ChunkedBytes::from_file(&local_file_path, MIN_CHUNK_SIZE as i32).await?;
  let ext = Path::new(&local_file_path)
    .extension()
    .and_then(std::ffi::OsStr::to_str)
    .unwrap_or("")
    .to_owned();
  let content_type = mime_guess::from_path(&local_file_path)
    .first_or_octet_stream()
    .to_string();
  let file_id = format!("{}.{}", fxhash::hash(&chunked_bytes.data), ext);
  let record = UploadFileTable {
    workspace_id,
    file_id,
    upload_id: "".to_string(),
    parent_dir,
    local_file_path,
    content_type,
    chunk_size: chunked_bytes.chunk_size,
    num_chunk: chunked_bytes.offsets.len() as i32,
    created_at: timestamp(),
    is_finish: false,
  };
  Ok((chunked_bytes, record))
}

#[instrument(level = "debug", skip_all, err)]
async fn start_upload(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  temp_storage: &Arc<FileTempStorage>,
  mut chunked_bytes: ChunkedBytes,
  upload_file: &UploadFileTable,
  progress_notifiers: Arc<DashMap<String, ProgressNotifier>>,
  global_notifier: GlobalNotifier,
) -> FlowyResult<()> {
  // 4. gather existing completed parts
  let mut conn = user_service.sqlite_connection(user_service.user_id()?)?;
  let mut completed_parts = select_upload_parts(&mut conn, &upload_file.upload_id)
    .unwrap_or_default()
    .into_iter()
    .map(|part| CompletedPartRequest {
      e_tag: part.e_tag,
      part_number: part.part_num,
    })
    .collect::<Vec<_>>();

  let upload_offset = completed_parts.len() as i32;
  chunked_bytes.set_current_offset(upload_offset);

  info!(
    "[File] start upload: workspace: {}, parent_dir: {}, file_id: {}, chunk: {}",
    upload_file.workspace_id, upload_file.parent_dir, upload_file.file_id, chunked_bytes,
  );

  let mut upload_file = upload_file.clone();
  if upload_file.upload_id.is_empty() {
    // 1. create upload
    trace!(
      "[File] create upload for workspace: {}, parent_dir: {}, file_id: {}",
      upload_file.workspace_id,
      upload_file.parent_dir,
      upload_file.file_id
    );

    let create_upload_resp_result = cloud_service
      .create_upload(
        &upload_file.workspace_id,
        &upload_file.parent_dir,
        &upload_file.file_id,
        &upload_file.content_type,
      )
      .await;
    if let Err(err) = create_upload_resp_result.as_ref() {
      if err.is_file_limit_exceeded() {
        make_notification(StorageNotification::FileStorageLimitExceeded)
          .payload(err.clone())
          .send();
      }
    }
    let create_upload_resp = create_upload_resp_result?;

    // 2. update upload_id
    let conn = user_service.sqlite_connection(user_service.user_id()?)?;
    update_upload_file_upload_id(
      conn,
      &upload_file.workspace_id,
      &upload_file.parent_dir,
      &upload_file.file_id,
      &create_upload_resp.upload_id,
    )?;

    trace!(
      "[File] {} update upload_id: {}",
      upload_file.file_id,
      create_upload_resp.upload_id
    );
    // temporary store the upload_id
    upload_file.upload_id = create_upload_resp.upload_id;
  }

  // 3. start uploading parts
  trace!(
    "[File] {} start uploading parts: {}",
    upload_file.file_id,
    chunked_bytes.iter().count()
  );
  let total_parts = chunked_bytes.iter().count();
  let iter = chunked_bytes.iter().enumerate();

  for (index, chunk_bytes) in iter {
    let part_number = upload_offset + index as i32 + 1;
    trace!(
      "[File] {} uploading {}th part, size:{}KB",
      upload_file.file_id,
      part_number,
      chunk_bytes.len() / 1000,
    );
    // start uploading parts
    match upload_part(
      cloud_service,
      user_service,
      &upload_file.workspace_id,
      &upload_file.parent_dir,
      &upload_file.upload_id,
      &upload_file.file_id,
      part_number as i32,
      chunk_bytes.to_vec(),
    )
    .await
    {
      Ok(resp) => {
        let progress = (part_number as f64 / total_parts as f64).clamp(0.0, 1.0);
        trace!(
          "[File] {} upload progress: {}",
          upload_file.file_id,
          progress
        );

        if let Err(err) = global_notifier.send(FileProgress {
          file_id: upload_file.file_id.clone(),
          progress,
          error: None,
        }) {
          error!("[File] send global notifier failed: {}", err);
        }

        if let Some(mut notifier) = progress_notifiers.get_mut(&upload_file.file_id) {
          notifier
            .notify(FileUploadState::Uploading { progress })
            .await;
        }

        // gather completed part
        completed_parts.push(CompletedPartRequest {
          e_tag: resp.e_tag,
          part_number: resp.part_num,
        });
      },
      Err(err) => {
        if err.is_file_limit_exceeded() {
          make_notification(StorageNotification::FileStorageLimitExceeded)
            .payload(err.clone())
            .send();
        }

        error!("[File] {} upload part failed: {}", upload_file.file_id, err);
        return Err(err);
      },
    }
  }

  // mark it as completed
  let complete_upload_result = complete_upload(
    cloud_service,
    user_service,
    temp_storage,
    &upload_file,
    completed_parts,
    &progress_notifiers,
    &global_notifier,
  )
  .await;
  if let Err(err) = complete_upload_result {
    if err.is_file_limit_exceeded() {
      make_notification(StorageNotification::FileStorageLimitExceeded)
        .payload(err.clone())
        .send();
    }
  }

  trace!("[File] {} upload completed", upload_file.file_id);
  Ok(())
}

#[instrument(level = "debug", skip_all, err)]
async fn resume_upload(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  temp_storage: &Arc<FileTempStorage>,
  upload_file: UploadFileTable,
  progress_notifiers: Arc<DashMap<String, ProgressNotifier>>,
  global_notifier: GlobalNotifier,
) -> FlowyResult<()> {
  trace!(
    "[File] resume upload for workspace: {}, parent_dir: {}, file_id: {}, local_file_path:{}",
    upload_file.workspace_id,
    upload_file.parent_dir,
    upload_file.file_id,
    upload_file.local_file_path
  );

  match ChunkedBytes::from_file(&upload_file.local_file_path, MIN_CHUNK_SIZE as i32).await {
    Ok(chunked_bytes) => {
      // When there were any parts already uploaded, skip those parts by setting the current offset.
      start_upload(
        cloud_service,
        user_service,
        temp_storage,
        chunked_bytes,
        &upload_file,
        progress_notifiers,
        global_notifier,
      )
      .await?;
    },
    Err(err) => {
      //
      match err.kind() {
        ErrorKind::NotFound => {
          error!("[File] file not found: {}", upload_file.local_file_path);
          if let Ok(uid) = user_service.user_id() {
            if let Ok(conn) = user_service.sqlite_connection(uid) {
              delete_upload_file(conn, &upload_file.upload_id)?;
            }
          }
        },
        _ => {
          error!("[File] read file failed: {}", err);
        },
      }
    },
  }
  Ok(())
}

#[allow(clippy::too_many_arguments)]
#[instrument(level = "debug", skip_all)]
async fn upload_part(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  workspace_id: &str,
  parent_dir: &str,
  upload_id: &str,
  file_id: &str,
  part_number: i32,
  body: Vec<u8>,
) -> Result<UploadPartResponse, FlowyError> {
  let resp = cloud_service
    .upload_part(
      workspace_id,
      parent_dir,
      upload_id,
      file_id,
      part_number,
      body,
    )
    .await?;

  // save uploaded part to sqlite
  let conn = user_service.sqlite_connection(user_service.user_id()?)?;
  insert_upload_part(
    conn,
    &UploadFilePartTable {
      upload_id: upload_id.to_string(),
      e_tag: resp.e_tag.clone(),
      part_num: resp.part_num,
    },
  )?;

  Ok(resp)
}

async fn complete_upload(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  temp_storage: &Arc<FileTempStorage>,
  upload_file: &UploadFileTable,
  parts: Vec<CompletedPartRequest>,
  progress_notifiers: &Arc<DashMap<String, ProgressNotifier>>,
  global_notifier: &GlobalNotifier,
) -> Result<(), FlowyError> {
  trace!(
    "[File]: completing file upload: {}, num parts: {}",
    upload_file.file_id,
    parts.len()
  );
  match cloud_service
    .complete_upload(
      &upload_file.workspace_id,
      &upload_file.parent_dir,
      &upload_file.upload_id,
      &upload_file.file_id,
      parts,
    )
    .await
  {
    Ok(_) => {
      info!("[File] completed upload file: {}", upload_file.file_id);
      if let Some(mut notifier) = progress_notifiers.get_mut(&upload_file.file_id) {
        info!("[File]: notify upload:{} finished", upload_file.file_id);
        notifier
          .notify(FileUploadState::Finished {
            file_id: upload_file.file_id.clone(),
          })
          .await;
      }

      if let Err(err) = global_notifier.send(FileProgress {
        file_id: upload_file.file_id.clone(),
        progress: 1.0,
        error: None,
      }) {
        error!("[File] send global notifier failed: {}", err);
      }

      let conn = user_service.sqlite_connection(user_service.user_id()?)?;
      update_upload_file_completed(conn, &upload_file.upload_id)?;
      if let Err(err) = temp_storage
        .delete_temp_file(&upload_file.local_file_path)
        .await
      {
        error!("[File] delete temp file failed: {}", err);
      }
    },
    Err(err) => {
      error!("[File] complete upload failed: {}", err);
    },
  }
  Ok(())
}

pub async fn object_from_disk(
  workspace_id: &str,
  local_file_path: &str,
) -> Result<(ObjectIdentity, ObjectValue), FlowyError> {
  let ext = Path::new(local_file_path)
    .extension()
    .and_then(std::ffi::OsStr::to_str)
    .unwrap_or("")
    .to_owned();
  let mut file = tokio::fs::File::open(local_file_path).await?;
  let mut content = Vec::new();
  let n = file.read_to_end(&mut content).await?;
  info!("read {} bytes from file: {}", n, local_file_path);
  let mime = mime_guess::from_path(local_file_path).first_or_octet_stream();
  let hash = fxhash::hash(&content);

  Ok((
    ObjectIdentity {
      workspace_id: workspace_id.to_owned(),
      file_id: hash.to_string(),
      ext,
    },
    ObjectValue {
      raw: content.into(),
      mime,
    },
  ))
}
