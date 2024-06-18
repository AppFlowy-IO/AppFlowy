use crate::chunked_byte::{ChunkedBytes, MIN_CHUNK_SIZE};
use crate::sqlite_sql::{
  batch_select_upload_file, delete_upload_file, insert_upload_file, insert_upload_part,
  select_upload_file, select_upload_parts, update_upload_file_upload_id, UploadFilePartTable,
  UploadFileTable,
};
use crate::uploader::{FileUploader, FileUploaderRunner, Signal, UploadTask};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, StorageService, UploadPartResponse};
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::select;
use tokio::sync::{mpsc, watch, RwLock};
use tokio::time::interval;
use tracing::{debug, error, info, trace};

pub trait StorageUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}

pub struct StorageManager {
  user_service: Arc<dyn StorageUserService>,
  pub storage_service: Arc<dyn StorageService>,
  stop_tx: Arc<RwLock<Option<mpsc::Sender<()>>>>,
  uploader: Arc<FileUploader>,
}

impl StorageManager {
  pub fn new(
    cloud_service: Arc<dyn StorageCloudService>,
    user_service: Arc<dyn StorageUserService>,
  ) -> Self {
    let (notifier, notifier_rx) = watch::channel(Signal::Proceed);
    let storage_service = Arc::new(StorageServiceImpl {
      cloud_service,
      user_service: user_service.clone(),
    });

    let uploader = Arc::new(FileUploader::new(storage_service.clone(), notifier));
    tokio::spawn(FileUploaderRunner::run(
      Arc::downgrade(&uploader),
      notifier_rx,
    ));

    let cloned_uploader = uploader.clone();
    let cloned_user_service = user_service.clone();
    tokio::spawn(async move {
      if let Err(err) = prepare_upload_task(cloned_uploader, cloned_user_service).await {
        error!("prepare upload task failed: {}", err);
      }
    });

    Self {
      user_service,
      storage_service,
      stop_tx: Arc::new(RwLock::new(None)),
      uploader,
    }
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
    })
    .collect::<Vec<_>>();
  info!("prepare upload task: {}", tasks.len());
  uploader.queue_tasks(tasks).await;
  Ok(())
}

pub struct StorageServiceImpl {
  cloud_service: Arc<dyn StorageCloudService>,
  user_service: Arc<dyn StorageUserService>,
}

impl StorageService for StorageServiceImpl {
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

  fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    local_file_path: &str,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let parent_dir = parent_dir.to_string();
    let local_file_path = local_file_path.to_string();
    let cloud_service = self.cloud_service.clone();
    let user_service = self.user_service.clone();

    FutureResult::new(async move {
      // 1. read file and chunk it base on CHUNK_SIZE. We use MIN_CHUNK_SIZE as the minimum chunk size
      let chunked_bytes = ChunkedBytes::from_file(&local_file_path, MIN_CHUNK_SIZE as i32).await?;
      let content_type = mime_guess::from_path(&local_file_path)
        .first_or_octet_stream()
        .to_string();
      let num_of_chunk = chunked_bytes.offsets.len();
      let file_id = fxhash::hash(&chunked_bytes.data).to_string();
      let record = UploadFileTable {
        workspace_id,
        file_id,
        upload_id: "".to_string(),
        parent_dir,
        local_file_path,
        content_type,
        chunk_size: chunked_bytes.chunk_size,
        num_chunk: num_of_chunk as i32,
        created_at: timestamp(),
      };

      // 2. save the record to sqlite
      let conn = user_service.sqlite_connection(user_service.user_id()?)?;
      insert_upload_file(conn, &record)?;

      // 3. start uploading
      start_upload(&cloud_service, &user_service, chunked_bytes, record).await?;
      Ok(())
    })
  }

  fn resume_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> FutureResult<(), FlowyError> {
    let file_id = file_id.to_string();
    let workspace_id = workspace_id.to_string();
    let parent_dir = parent_dir.to_string();
    let cloud_service = self.cloud_service.clone();
    let user_service = self.user_service.clone();
    FutureResult::new(async move {
      // Gathering the upload record and parts from the sqlite database.
      let record = {
        let mut conn = user_service.sqlite_connection(user_service.user_id()?)?;
        conn.immediate_transaction(|conn| {
          Ok::<_, FlowyError>(
            // When resuming an upload, check if the upload_id is empty.
            // If the upload_id is empty, the upload has likely not been created yet.
            // If the upload_id is not empty, verify which parts have already been uploaded.
            select_upload_file(conn, &workspace_id, &parent_dir, &file_id)?.and_then(|record| {
              if record.upload_id.is_empty() {
                Some((record, vec![]))
              } else {
                let parts = select_upload_parts(conn, &record.upload_id).unwrap_or_default();
                Some((record, parts))
              }
            }),
          )
        })?
      };

      if let Some((upload_file, parts)) = record {
        resume_upload(&cloud_service, &user_service, upload_file, parts).await?;
      } else {
        error!("[File] resume upload failed: record not found");
      }
      Ok(())
    })
  }
}

async fn start_upload(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  chunked_bytes: ChunkedBytes,
  mut upload_file: UploadFileTable,
) -> FlowyResult<()> {
  if upload_file.upload_id.is_empty() {
    // 1. create upload
    let create_upload_resp = cloud_service
      .create_upload(
        &upload_file.workspace_id,
        &upload_file.parent_dir,
        &upload_file.file_id,
        &upload_file.content_type,
      )
      .await?;
    // 2. update upload_id
    let conn = user_service.sqlite_connection(user_service.user_id()?)?;
    update_upload_file_upload_id(
      conn,
      &upload_file.workspace_id,
      &upload_file.parent_dir,
      &upload_file.file_id,
      &create_upload_resp.upload_id,
    )?;

    // temporary store the upload_id
    upload_file.upload_id = create_upload_resp.upload_id;
  }

  // 3. start uploading parts
  let mut iter = chunked_bytes.iter().enumerate();
  let mut completed_parts = Vec::new();
  while let Some((index, chunk_bytes)) = iter.next() {
    let part_number = index as i32 + 1;
    // start uploading parts
    match upload_part(
      &cloud_service,
      &user_service,
      &upload_file.workspace_id,
      &upload_file.parent_dir,
      &upload_file.upload_id,
      &upload_file.file_id,
      part_number,
      chunk_bytes.to_vec(),
    )
    .await
    {
      Ok(resp) => {
        trace!(
          "[File] upload {} part success, total:{},",
          part_number,
          chunked_bytes.offsets.len()
        );
        // gather completed part
        completed_parts.push(CompletedPartRequest {
          e_tag: resp.e_tag,
          part_number: resp.part_num,
        });
      },
      Err(err) => {
        error!("[File] upload part failed: {}", err);
      },
    }
  }

  // mark it as completed
  complete_upload(
    &cloud_service,
    &user_service,
    &upload_file.workspace_id,
    &upload_file.parent_dir,
    &upload_file.upload_id,
    &upload_file.file_id,
    completed_parts,
  )
  .await?;
  Ok(())
}

async fn resume_upload(
  cloud_service: &Arc<dyn StorageCloudService>,
  user_service: &Arc<dyn StorageUserService>,
  upload_file: UploadFileTable,
  parts: Vec<UploadFilePartTable>,
) -> FlowyResult<()> {
  let mut chunked_bytes =
    ChunkedBytes::from_file(&upload_file.local_file_path, MIN_CHUNK_SIZE as i32).await?;

  // When there were any parts already uploaded, skip those parts by setting the current offset.
  chunked_bytes.set_current_offset(parts.len() as i32);
  start_upload(cloud_service, user_service, chunked_bytes, upload_file).await?;
  Ok(())
}

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
      &workspace_id,
      &parent_dir,
      &upload_id,
      &file_id,
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
  workspace_id: &str,
  parent_dir: &str,
  upload_id: &str,
  file_id: &str,
  parts: Vec<CompletedPartRequest>,
) -> Result<(), FlowyError> {
  match cloud_service
    .complete_upload(&workspace_id, &parent_dir, &upload_id, &file_id, parts)
    .await
  {
    Ok(_) => {
      info!("[File] completed upload file: {}", upload_id);
      trace!("[File] delete upload record from sqlite");
      let conn = user_service.sqlite_connection(user_service.user_id()?)?;
      delete_upload_file(conn, &upload_id)?;
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
