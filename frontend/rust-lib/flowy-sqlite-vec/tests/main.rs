use anyhow::Result;
use flowy_sqlite_vec::db::{EmbeddedChunk, VectorSqliteDB};
use flowy_sqlite_vec::init_sqlite_vector_extension;
use tempfile::tempdir;
use uuid::Uuid;

#[test]
fn test_vector_sqlite_db_basic_operations() -> Result<()> {
  // Initialize sqlite-vec extension
  init_sqlite_vector_extension();

  // Create a temporary directory for the test database
  let temp_dir = tempdir()?;
  let db_path = temp_dir.path().join("test_vector.db");

  // Create the VectorSqliteDB
  let mut db = VectorSqliteDB::new(&db_path)?;

  // Test inserting vector embeddings
  let oid = Uuid::new_v4().to_string();
  let fragments = vec![
    create_test_fragment(&oid, 0, vec![0.1, 0.1, 0.1, 0.1]),
    create_test_fragment(&oid, 1, vec![0.2, 0.2, 0.2, 0.2]),
    create_test_fragment(&oid, 2, vec![0.3, 0.3, 0.3, 0.3]),
  ];

  db.upsert_collabs_embeddings(&oid, fragments)?;

  // Test querying fragment IDs
  let result = db.select_collabs_fragment_ids(&[oid.clone()])?;
  assert_eq!(result.len(), 1);
  assert!(result.contains_key(&Uuid::parse_str(&oid)?));
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 3);

  // Clean up
  db.close()?;

  Ok(())
}

#[test]
fn test_upsert_and_remove_fragments() -> Result<()> {
  // Initialize sqlite-vec extension
  init_sqlite_vector_extension();

  // Create a temporary directory for the test database
  let temp_dir = tempdir()?;
  let db_path = temp_dir.path().join("test_upsert_remove.db");

  // Create the VectorSqliteDB
  let mut db = VectorSqliteDB::new(&db_path)?;

  // Test inserting initial vector embeddings
  let oid = Uuid::new_v4().to_string();
  let initial_fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1)),
    create_test_fragment(&oid, 1, generate_embedding_with_size(768, 0.2)),
    create_test_fragment(&oid, 2, generate_embedding_with_size(768, 0.3)),
  ];

  db.upsert_collabs_embeddings(&oid, initial_fragments)?;

  // Verify initial fragments
  let result = db.select_collabs_fragment_ids(&[oid.clone()])?;
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 3);

  // Update with a subset of fragments (this should remove the missing one)
  let updated_fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1)),
    create_test_fragment(&oid, 2, generate_embedding_with_size(768, 0.3)),
  ];

  db.upsert_collabs_embeddings(&oid, updated_fragments)?;
  // Verify fragment count is now 2
  let result = db.select_collabs_fragment_ids(&[oid.clone()])?;
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 2);

  let result = db
    .search(&generate_embedding_with_size(768, 0.1), 1)
    .unwrap();
  assert!(!result.is_empty());
  assert_eq!(result[0].oid, oid);
  assert_eq!(result[0].content, "Content for fragment 0".to_string());
  dbg!(result);

  // Clean up
  db.close()?;

  Ok(())
}

fn generate_embedding_with_size(size: usize, value: f32) -> Vec<f32> {
  vec![value; size]
}

fn create_test_fragment(oid: &str, index: i32, embeddings: Vec<f32>) -> EmbeddedChunk {
  let fragment_id = format!("fragment_{}", index);

  EmbeddedChunk {
    fragment_id,
    oid: oid.to_string(),
    content_type: 1,
    content: format!("Content for fragment {}", index),
    metadata: Some(format!("Metadata for fragment {}", index)),
    fragment_index: index,
    embedder_type: 1,
    embeddings: Some(embeddings),
  }
}
