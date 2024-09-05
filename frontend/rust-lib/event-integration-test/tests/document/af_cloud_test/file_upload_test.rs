use crate::document::generate_random_bytes;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_storage_pub::storage::FileUploadState;
use lib_infra::util::md5;
use std::env::temp_dir;
use std::sync::Arc;
use std::time::Duration;
use tokio::fs;
use tokio::fs::File;
use tokio::io::AsyncWriteExt;
use tokio::sync::Mutex;
use tokio::time::timeout;

#[tokio::test]
async fn af_cloud_upload_big_file_test() {
  user_localhost_af_cloud().await;
  let mut test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  tokio::time::sleep(Duration::from_secs(6)).await;
  let parent_dir = "temp_test";
  let workspace_id = test.get_current_workspace().await.id;
  let (file_path, upload_data) = generate_file_with_bytes_len(15 * 1024 * 1024).await;
  let (created_upload, rx) = test
    .storage_manager
    .storage_service
    .create_upload(&workspace_id, parent_dir, &file_path, false)
    .await
    .unwrap();

  let mut rx = rx.unwrap();
  while let Ok(state) = rx.recv().await {
    if let FileUploadState::Uploading { progress } = state {
      if progress > 0.1 {
        break;
      }
    }
  }

  // Simulate a restart
  let config = test.config.clone();
  test.skip_clean();
  drop(test);
  tokio::time::sleep(Duration::from_secs(3)).await;

  // Restart the test. It will load unfinished uploads
  let test = EventIntegrationTest::new_with_config(config).await;
  if let Some(mut rx) = test
    .storage_manager
    .subscribe_file_state(parent_dir, &created_upload.file_id)
    .await
    .unwrap()
  {
    let timeout_duration = Duration::from_secs(180);
    while let Ok(state) = match timeout(timeout_duration, rx.recv()).await {
      Ok(result) => result,
      Err(_) => {
        panic!("Timed out waiting for file upload completion");
      },
    } {
      if let FileUploadState::Finished { .. } = state {
        break;
      }
    }
  }

  // download the file and then compare the data.
  let file_service = test
    .server_provider
    .get_server()
    .unwrap()
    .file_storage()
    .unwrap();
  let file = file_service.get_object(created_upload.url).await.unwrap();
  assert_eq!(md5(file.raw), md5(upload_data));
  let _ = fs::remove_file(file_path).await;
}

#[tokio::test]
async fn af_cloud_upload_6_files_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  let workspace_id = test.get_current_workspace().await.id;

  let mut created_uploads = vec![];
  let mut receivers = vec![];
  for file_size in [1, 2, 5, 8, 12, 20] {
    let file_path = generate_file_with_bytes_len(file_size * 1024 * 1024)
      .await
      .0;
    let (created_upload, rx) = test
      .storage_manager
      .storage_service
      .create_upload(&workspace_id, "temp_test", &file_path, false)
      .await
      .unwrap();
    receivers.push(rx.unwrap());
    created_uploads.push(created_upload);
    let _ = fs::remove_file(file_path).await;
  }

  // Wait for all uploads to finish
  let uploads = Arc::new(Mutex::new(created_uploads));
  let mut handles = vec![];

  for mut receiver in receivers {
    let cloned_uploads = uploads.clone();
    let state = test.storage_manager.get_file_state(&receiver.file_id).await;
    let handle = tokio::spawn(async move {
      if let Some(FileUploadState::Finished { file_id }) = state {
        cloned_uploads
          .lock()
          .await
          .retain(|upload| upload.file_id != file_id);
      }
      while let Ok(value) = receiver.recv().await {
        if let FileUploadState::Finished { file_id } = value {
          cloned_uploads
            .lock()
            .await
            .retain(|upload| upload.file_id != file_id);
          break;
        }
      }
    });
    handles.push(handle);
  }

  // join all handles
  futures::future::join_all(handles).await;
  assert_eq!(uploads.lock().await.len(), 0);
}

async fn generate_file_with_bytes_len(len: usize) -> (String, Vec<u8>) {
  let data = generate_random_bytes(len);
  let file_dir = temp_dir().join(uuid::Uuid::new_v4().to_string());
  let file_path = file_dir.to_str().unwrap().to_string();
  let mut file = File::create(file_dir).await.unwrap();
  file.write_all(&data).await.unwrap();

  (file_path, data)
}
