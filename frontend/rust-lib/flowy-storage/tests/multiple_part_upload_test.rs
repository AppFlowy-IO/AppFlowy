use flowy_sqlite::Database;
use flowy_storage::sqlite_sql::{
  batch_select_upload_file, delete_upload_file, insert_upload_file, insert_upload_part,
  select_latest_upload_part, select_upload_parts, UploadFilePartTable, UploadFileTable,
};
use flowy_storage_pub::chunked_byte::{ChunkedBytes, MIN_CHUNK_SIZE};
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use std::env::temp_dir;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::time::Duration;

pub fn test_database() -> (Database, PathBuf) {
  let db_path = temp_dir().join(&format!("test-{}.db", generate_random_string(8)));
  (flowy_sqlite::init(&db_path).unwrap(), db_path)
}

#[tokio::test]
async fn test_insert_new_upload() {
  let (db, _) = test_database();

  let workspace_id = uuid::Uuid::new_v4().to_string();

  // test insert one upload file record
  let mut upload_ids = vec![];
  for _i in 0..5 {
    let upload_id = uuid::Uuid::new_v4().to_string();
    let local_file_path = create_temp_file_with_random_content(8 * 1024 * 1024).unwrap();
    let upload_file =
      create_upload_file_record(workspace_id.clone(), upload_id.clone(), local_file_path).await;
    upload_ids.push(upload_file.upload_id.clone());

    // insert
    let conn = db.get_connection().unwrap();
    insert_upload_file(conn, &upload_file).unwrap();
    tokio::time::sleep(Duration::from_secs(1)).await;
  }
  upload_ids.reverse();

  // select
  let conn = db.get_connection().unwrap();
  let records = batch_select_upload_file(conn, 100).unwrap();

  assert_eq!(records.len(), 5);
  // compare the upload id order is the same as upload_ids
  for i in 0..5 {
    assert_eq!(records[i].upload_id, upload_ids[i]);

    // delete
    let conn = db.get_connection().unwrap();
    delete_upload_file(conn, &records[i].upload_id).unwrap();
  }

  let conn = db.get_connection().unwrap();
  let records = batch_select_upload_file(conn, 100).unwrap();
  assert!(records.is_empty());
}

#[tokio::test]
async fn test_upload_part_test() {
  let (db, _) = test_database();

  let workspace_id = uuid::Uuid::new_v4().to_string();

  // test insert one upload file record
  let upload_id = uuid::Uuid::new_v4().to_string();
  let local_file_path = create_temp_file_with_random_content(20 * 1024 * 1024).unwrap();
  let upload_file =
    create_upload_file_record(workspace_id.clone(), upload_id.clone(), local_file_path).await;

  // insert
  let conn = db.get_connection().unwrap();
  insert_upload_file(conn, &upload_file).unwrap();
  tokio::time::sleep(Duration::from_secs(1)).await;

  // insert uploaded part 1
  let part = UploadFilePartTable {
    upload_id: upload_id.clone(),
    e_tag: "1".to_string(),
    part_num: 1,
  };
  let conn = db.get_connection().unwrap();
  insert_upload_part(conn, &part).unwrap();

  // insert uploaded part 2
  let part = UploadFilePartTable {
    upload_id: upload_id.clone(),
    e_tag: "2".to_string(),
    part_num: 2,
  };
  let conn = db.get_connection().unwrap();
  insert_upload_part(conn, &part).unwrap();

  // get latest part
  let conn = db.get_connection().unwrap();
  let part = select_latest_upload_part(conn, &upload_id)
    .unwrap()
    .unwrap();
  assert_eq!(part.part_num, 2);

  // get all existing parts
  let mut conn = db.get_connection().unwrap();
  let parts = select_upload_parts(&mut *conn, &upload_id).unwrap();
  assert_eq!(parts.len(), 2);
  assert_eq!(parts[0].part_num, 1);
  assert_eq!(parts[1].part_num, 2);

  // delete upload file and then all existing parts will be deleted
  let conn = db.get_connection().unwrap();
  delete_upload_file(conn, &upload_id).unwrap();

  let mut conn = db.get_connection().unwrap();
  let parts = select_upload_parts(&mut *conn, &upload_id).unwrap();
  assert!(parts.is_empty())
}

pub fn generate_random_string(len: usize) -> String {
  let rng = thread_rng();
  rng
    .sample_iter(&Alphanumeric)
    .take(len)
    .map(char::from)
    .collect()
}

fn create_temp_file_with_random_content(
  size_in_bytes: usize,
) -> Result<String, Box<dyn std::error::Error>> {
  // Generate a random string of the specified size
  let content: String = rand::thread_rng()
    .sample_iter(&Alphanumeric)
    .take(size_in_bytes)
    .map(char::from)
    .collect();

  // Create a temporary file path
  let file_path = std::env::temp_dir().join("test.txt");

  // Write the content to the temporary file
  let mut file = File::create(&file_path)?;
  file.write_all(content.as_bytes())?;

  // Return the file path
  Ok(file_path.to_str().unwrap().to_string())
}

pub async fn create_upload_file_record(
  workspace_id: String,
  upload_id: String,
  local_file_path: String,
) -> UploadFileTable {
  // Create ChunkedBytes from file
  let chunked_bytes = ChunkedBytes::from_file(&local_file_path, MIN_CHUNK_SIZE as i32)
    .await
    .unwrap();

  // Determine content type
  let content_type = mime_guess::from_path(&local_file_path)
    .first_or_octet_stream()
    .to_string();

  // Calculate file ID
  let file_id = fxhash::hash(&chunked_bytes.data).to_string();

  // Create UploadFileTable record
  let upload_file = UploadFileTable {
    workspace_id,
    file_id,
    upload_id,
    parent_dir: "test".to_string(),
    local_file_path,
    content_type,
    chunk_size: MIN_CHUNK_SIZE as i32,
    num_chunk: chunked_bytes.offsets.len() as i32,
    created_at: chrono::Utc::now().timestamp(),
  };

  upload_file
}
