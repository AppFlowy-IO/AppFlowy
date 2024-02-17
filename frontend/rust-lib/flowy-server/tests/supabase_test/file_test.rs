// use url::Url;
// use uuid::Uuid;
//
// use flowy_storage::StorageObject;
//
// use crate::supabase_test::util::{file_storage_service, get_supabase_ci_config};
//
// #[tokio::test]
// async fn supabase_get_object_test() {
//   if get_supabase_ci_config().is_none() {
//     return;
//   }
//
//   let service = file_storage_service();
//   let file_name = format!("test-{}.txt", Uuid::new_v4());
//   let object = StorageObject::from_file("1", &file_name, "tests/test.txt");
//
//   // Upload a file
//   let url = service
//     .create_object(object)
//     .await
//     .unwrap()
//     .parse::<Url>()
//     .unwrap();
//
//   // The url would be something like:
//   // https://acfrqdbdtbsceyjbxsfc.supabase.co/storage/v1/object/data/test-1693472809.txt
//   let name = url.path_segments().unwrap().last().unwrap();
//   assert_eq!(name, &file_name);
//
//   // Download the file
//   let bytes = service.get_object(url.to_string()).await.unwrap();
//   let s = String::from_utf8(bytes.to_vec()).unwrap();
//   assert_eq!(s, "hello world");
// }
//
// #[tokio::test]
// async fn supabase_upload_image_test() {
//   if get_supabase_ci_config().is_none() {
//     return;
//   }
//
//   let service = file_storage_service();
//   let file_name = format!("image-{}.png", Uuid::new_v4());
//   let object = StorageObject::from_file("1", &file_name, "tests/logo.png");
//
//   // Upload a file
//   let url = service
//     .create_object(object)
//     .await
//     .unwrap()
//     .parse::<Url>()
//     .unwrap();
//
//   // Download object by url
//   let bytes = service.get_object(url.to_string()).await.unwrap();
//   assert_eq!(bytes.len(), 15694);
// }
//
// #[tokio::test]
// async fn supabase_delete_object_test() {
//   if get_supabase_ci_config().is_none() {
//     return;
//   }
//
//   let service = file_storage_service();
//   let file_name = format!("test-{}.txt", Uuid::new_v4());
//   let object = StorageObject::from_file("1", &file_name, "tests/test.txt");
//   let url = service.create_object(object).await.unwrap();
//
//   let result = service.get_object(url.clone()).await;
//   assert!(result.is_ok());
//
//   let _ = service.delete_object(url.clone()).await;
//
//   let result = service.get_object(url.clone()).await;
//   assert!(result.is_err());
// }
