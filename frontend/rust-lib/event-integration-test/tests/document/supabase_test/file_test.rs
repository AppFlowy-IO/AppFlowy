// use std::fs::File;
// use std::io::{Cursor, Read};
// use std::path::Path;
//
// use uuid::Uuid;
// use zip::ZipArchive;
//
// use flowy_storage::StorageObject;
//
// use crate::document::supabase_test::helper::FlowySupabaseDocumentTest;
//
// #[tokio::test]
// async fn supabase_document_upload_text_file_test() {
//   if let Some(test) = FlowySupabaseDocumentTest::new().await {
//     let workspace_id = test.get_current_workspace().await.id;
//     let storage_service = test
//       .document_manager
//       .get_file_storage_service()
//       .upgrade()
//       .unwrap();
//
//     let object = StorageObject::from_bytes(
//       &workspace_id,
//       &Uuid::new_v4().to_string(),
//       "hello world".as_bytes(),
//       "text/plain".to_string(),
//     );
//
//     let url = storage_service.create_object(object).await.unwrap();
//
//     let bytes = storage_service
//       .get_object(url.clone())
//       .await
//       .unwrap();
//     let s = String::from_utf8(bytes.to_vec()).unwrap();
//     assert_eq!(s, "hello world");
//
//     // Delete the text file
//     let _ = storage_service.delete_object(url).await;
//   }
// }
//
// #[tokio::test]
// async fn supabase_document_upload_zip_file_test() {
//   if let Some(test) = FlowySupabaseDocumentTest::new().await {
//     let workspace_id = test.get_current_workspace().await.id;
//     let storage_service = test
//       .document_manager
//       .get_file_storage_service()
//       .upgrade()
//       .unwrap();
//
//     // Upload zip file
//     let object = StorageObject::from_file(
//       &workspace_id,
//       &Uuid::new_v4().to_string(),
//       "./tests/asset/test.txt.zip",
//     );
//     let url = storage_service.create_object(object).await.unwrap();
//
//     // Read zip file
//     let zip_data = storage_service
//       .get_object(url.clone())
//       .await
//       .unwrap();
//     let reader = Cursor::new(zip_data);
//     let mut archive = ZipArchive::new(reader).unwrap();
//     for i in 0..archive.len() {
//       let mut file = archive.by_index(i).unwrap();
//       let name = file.name().to_string();
//       let mut out = Vec::new();
//       file.read_to_end(&mut out).unwrap();
//
//       if name.starts_with("__MACOSX/") {
//         continue;
//       }
//       assert_eq!(name, "test.txt");
//       assert_eq!(String::from_utf8(out).unwrap(), "hello world");
//     }
//
//     // Delete the zip file
//     let _ = storage_service.delete_object(url).await;
//   }
// }
// #[tokio::test]
// async fn supabase_document_upload_image_test() {
//   if let Some(test) = FlowySupabaseDocumentTest::new().await {
//     let workspace_id = test.get_current_workspace().await.id;
//     let storage_service = test
//       .document_manager
//       .get_file_storage_service()
//       .upgrade()
//       .unwrap();
//
//     // Upload zip file
//     let object = StorageObject::from_file(
//       &workspace_id,
//       &Uuid::new_v4().to_string(),
//       "./tests/asset/logo.png",
//     );
//     let url = storage_service.create_object(object).await.unwrap();
//
//     let image_data = storage_service
//       .get_object(url.clone())
//       .await
//       .unwrap();
//
//     // Read the image file
//     let mut file = File::open(Path::new("./tests/asset/logo.png")).unwrap();
//     let mut local_data = Vec::new();
//     file.read_to_end(&mut local_data).unwrap();
//
//     assert_eq!(image_data, local_data);
//
//     // Delete the image
//     let _ = storage_service.delete_object(url).await;
//   }
// }
