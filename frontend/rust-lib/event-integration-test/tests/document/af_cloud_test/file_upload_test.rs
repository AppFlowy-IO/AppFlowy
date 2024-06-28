use crate::document::generate_random_bytes;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_storage_pub::storage::UploadStatus;
use std::env::temp_dir;
use std::time::Duration;
use tokio::fs;
use tokio::fs::File;
use tokio::io::AsyncWriteExt;

#[tokio::test]
async fn af_cloud_upload_file_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let workspace_id = test.get_current_workspace().await.id;
  let file_path = generate_file_with_bytes_len(1024).await.0;
  let mut rx = test.storage_manager.subscribe_upload_result();

  let created_upload = test
    .storage_manager
    .storage_service
    .create_upload(&workspace_id, "temp_test", &file_path)
    .await
    .unwrap();

  while let Ok(result) = rx.recv().await {
    if result.file_id == created_upload.file_id && result.status == UploadStatus::Finish {
      break;
    }
  }

  let _ = fs::remove_file(file_path).await;
}

#[tokio::test]
async fn af_cloud_upload_big_file_test() {
  user_localhost_af_cloud().await;
  let mut test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  tokio::time::sleep(Duration::from_secs(6)).await;

  let workspace_id = test.get_current_workspace().await.id;
  let (file_path, upload_data) = generate_file_with_bytes_len(30 * 1024 * 1024).await;
  let created_upload = test
    .storage_manager
    .storage_service
    .create_upload(&workspace_id, "temp_test", &file_path)
    .await
    .unwrap();

  let mut rx = test.storage_manager.subscribe_upload_result();
  while let Ok(result) = rx.recv().await {
    if result.file_id == created_upload.file_id && result.status == UploadStatus::InProgress {
      break;
    }
  }

  // Simulate a restart
  let config = test.config.clone();
  test.set_no_cleanup();
  drop(test);
  tokio::time::sleep(Duration::from_secs(3)).await;

  // Restart the test. It will load unfinished uploads
  let test = EventIntegrationTest::new_with_config(config).await;
  let mut rx = test.storage_manager.subscribe_upload_result();
  while let Ok(result) = rx.recv().await {
    if result.file_id == created_upload.file_id && result.status == UploadStatus::Finish {
      break;
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
  assert_eq!(file.raw.to_vec(), upload_data);

  let _ = fs::remove_file(file_path).await;
}

#[tokio::test]
async fn af_cloud_upload_6_files_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let workspace_id = test.get_current_workspace().await.id;
  let mut rx = test.storage_manager.subscribe_upload_result();

  let mut created_uploads = vec![];
  for file_size in [1, 2, 5, 8, 12, 20] {
    let file_path = generate_file_with_bytes_len(file_size * 1024 * 1024)
      .await
      .0;
    let created_upload = test
      .storage_manager
      .storage_service
      .create_upload(&workspace_id, "temp_test", &file_path)
      .await
      .unwrap();
    created_uploads.push(created_upload);

    let _ = fs::remove_file(file_path).await;
  }

  while let Ok(result) = rx.recv().await {
    if result.status == UploadStatus::Finish {
      created_uploads.retain(|upload| upload.file_id != result.file_id);
    }

    if created_uploads.is_empty() {
      break;
    }
  }
}

async fn generate_file_with_bytes_len(len: usize) -> (String, Vec<u8>) {
  let data = generate_random_bytes(len);
  let file_dir = temp_dir().join(uuid::Uuid::new_v4().to_string());
  let file_path = file_dir.to_str().unwrap().to_string();
  let mut file = File::create(file_dir).await.unwrap();
  file.write_all(&data).await.unwrap();

  (file_path, data)
}
