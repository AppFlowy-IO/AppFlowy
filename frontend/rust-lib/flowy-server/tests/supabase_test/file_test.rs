use crate::supabase_test::util::{file_storage_service, get_supabase_ci_config};

#[tokio::test]
async fn supabase_get_object_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = file_storage_service();
  let file_name = format!("test-{}.txt", chrono::Utc::now().timestamp());

  // Upload a file
  let key = service
    .create_object(&file_name, "tests/test.txt")
    .await
    .unwrap();
  assert_eq!(key, format!("data/{}", file_name));

  // Download the file
  let bytes = service.get_object(&file_name).await.unwrap();
  assert_eq!(bytes.len(), 248);
}

#[tokio::test]
async fn supabase_delete_object_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let service = file_storage_service();
  let file_name = format!("test-{}.txt", chrono::Utc::now().timestamp());
  let _ = service
    .create_object(&file_name, "tests/test.txt")
    .await
    .unwrap();

  let result = service.get_object(&file_name).await;
  assert!(result.is_ok());

  let _ = service.delete_object(&file_name).await;

  let result = service.get_object(&file_name).await;
  assert!(result.is_err());
}
