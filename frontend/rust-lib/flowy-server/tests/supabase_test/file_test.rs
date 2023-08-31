use url::Url;

use flowy_storage::core::StorageObject;

use crate::supabase_test::util::{file_storage_service, get_supabase_ci_config};

#[tokio::test]
async fn supabase_get_object_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = file_storage_service();
  let file_name = format!("test-{}.txt", chrono::Utc::now().timestamp());
  let object = StorageObject::from_file(&file_name, "tests/test.txt");

  // Upload a file
  let url = service
    .create_object(object)
    .await
    .unwrap()
    .parse::<Url>()
    .unwrap();

  // The url would be something like:
  // https://acfrqdbdtbsceyjbxsfc.supabase.co/storage/v1/object/data/test-1693472809.txt
  let name = url.path_segments().unwrap().last().unwrap();
  assert_eq!(name, &file_name);

  // Download the file
  let bytes = service.get_object(&file_name).await.unwrap();
  assert!(!bytes.is_empty());
}

#[tokio::test]
async fn supabase_upload_image_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = file_storage_service();
  let file_name = format!("image-{}.png", chrono::Utc::now().timestamp());
  let object = StorageObject::from_file(&file_name, "tests/logo.png");

  // Upload a file
  let _ = service
    .create_object(object)
    .await
    .unwrap()
    .parse::<Url>()
    .unwrap();

  // Download the file
  let bytes = service.get_object(&file_name).await.unwrap();
  assert!(!bytes.is_empty());
}

#[tokio::test]
async fn supabase_delete_object_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = file_storage_service();
  let file_name = format!("test-{}.txt", chrono::Utc::now().timestamp());
  let object = StorageObject::from_file(&file_name, "tests/test.txt");
  let _ = service.create_object(object).await.unwrap();

  let result = service.get_object(&file_name).await;
  assert!(result.is_ok());

  let _ = service.delete_object(&file_name).await;

  let result = service.get_object(&file_name).await;
  assert!(result.is_err());
}
