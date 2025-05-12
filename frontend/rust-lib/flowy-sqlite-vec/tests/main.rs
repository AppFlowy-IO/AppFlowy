use anyhow::Result;
use flowy_ai_pub::entities::EmbeddedChunk;
use flowy_sqlite_vec::db::VectorSqliteDB;
use flowy_sqlite_vec::init_sqlite_vector_extension;
use std::collections::HashSet;
use tempfile::tempdir;
use uuid::Uuid;

#[tokio::test]
async fn test_vector_sqlite_db_basic_operations() -> Result<()> {
  // Create a temporary directory for the test database
  let temp_dir = tempdir()?;

  // Create the VectorSqliteDB
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  // Test inserting vector embeddings
  let oid = Uuid::new_v4().to_string();
  let fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1)),
    create_test_fragment(&oid, 1, generate_embedding_with_size(768, 0.2)),
    create_test_fragment(&oid, 2, generate_embedding_with_size(768, 0.3)),
  ];
  let workspace_id = Uuid::new_v4();
  db.upsert_collabs_embeddings(&workspace_id.to_string(), &oid, fragments)
    .await?;

  // Test querying fragment IDs
  let result = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  assert_eq!(result.len(), 1);
  assert!(result.contains_key(&Uuid::parse_str(&oid)?));
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 3);

  Ok(())
}

#[tokio::test]
async fn test_upsert_and_remove_fragments() -> Result<()> {
  // Create a temporary directory for the test database
  let temp_dir = tempdir()?;

  // Create the VectorSqliteDB
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  // Test inserting initial vector embeddings
  let oid = Uuid::new_v4().to_string();
  let initial_fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1)),
    create_test_fragment(&oid, 1, generate_embedding_with_size(768, 0.2)),
    create_test_fragment(&oid, 2, generate_embedding_with_size(768, 0.3)),
  ];

  let workspace_id = Uuid::new_v4();
  db.upsert_collabs_embeddings(&workspace_id.to_string(), &oid, initial_fragments)
    .await?;

  // Verify initial fragments
  let result = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 3);

  // Update with a subset of fragments (this should remove the missing one)
  let updated_fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1)),
    create_test_fragment(&oid, 2, generate_embedding_with_size(768, 0.3)),
  ];

  db.upsert_collabs_embeddings(&workspace_id.to_string(), &oid, updated_fragments)
    .await?;
  // Verify fragment count is now 2
  let result = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  assert_eq!(result.get(&Uuid::parse_str(&oid)?).unwrap().len(), 2);

  let result = db
    .search(
      &workspace_id.to_string(),
      &[],
      &generate_embedding_with_size(768, 0.1),
      1,
    )
    .await
    .unwrap();
  assert!(!result.is_empty());
  assert_eq!(result[0].oid, Uuid::parse_str(&oid).unwrap());
  assert_eq!(result[0].content, "Content for fragment 0".to_string());
  dbg!(result);

  Ok(())
}

#[tokio::test]
async fn test_empty_fragments_noop_and_select_empty() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let oid = Uuid::new_v4().to_string();
  let workspace_id = Uuid::new_v4().to_string();

  // Upsert with an empty fragments Vec should not error and not insert anything
  db.upsert_collabs_embeddings(&workspace_id, &oid, Vec::new())
    .await?;

  // select_collabs_fragment_ids should return an empty map
  let result = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  assert!(
    result.is_empty(),
    "Expected no fragments stored, got {:?}",
    result
  );

  Ok(())
}

#[tokio::test]
async fn test_duplicate_upsert_idempotent() -> Result<()> {
  init_sqlite_vector_extension();
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let oid = Uuid::new_v4().to_string();
  let workspace_id = Uuid::new_v4().to_string();
  let fragments = vec![
    create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.5)),
    create_test_fragment(&oid, 1, generate_embedding_with_size(768, 0.6)),
  ];

  // First upsert
  db.upsert_collabs_embeddings(&workspace_id, &oid, fragments.clone())
    .await?;
  let first = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  let set1: HashSet<_> = first
    .get(&Uuid::parse_str(&oid)?)
    .unwrap()
    .clone()
    .into_iter()
    .collect();

  // Second upsert with the exact same fragments
  db.upsert_collabs_embeddings(&workspace_id, &oid, fragments)
    .await?;
  let second = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  let set2: HashSet<_> = second
    .get(&Uuid::parse_str(&oid)?)
    .unwrap()
    .clone()
    .into_iter()
    .collect();

  assert_eq!(
    set1, set2,
    "Upserting the same fragments should be idempotent"
  );
  Ok(())
}

#[tokio::test]
async fn test_search_no_hits() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let oid = Uuid::new_v4().to_string();
  let workspace_id = Uuid::new_v4().to_string();
  // Insert a single fragment at vector [1.0,...]
  let frags = vec![create_test_fragment(
    &oid,
    0,
    generate_embedding_with_size(768, 1.0),
  )];
  db.upsert_collabs_embeddings(&workspace_id, &oid, frags)
    .await?;

  // Query with a very different vector should return empty
  let query = generate_embedding_with_size(768, -1.0);
  let results = db.search(&workspace_id, &[], &query, 1).await?;
  assert!(
    results.is_empty(),
    "Expected no near neighbors for orthogonal vector"
  );
  Ok(())
}

#[tokio::test]
async fn test_multi_workspace_isolation() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let oid = Uuid::new_v4().to_string();
  let ws1 = Uuid::new_v4().to_string();
  let ws2 = Uuid::new_v4().to_string();

  // Insert identical fragment into two workspaces but with different embeddings
  let frag = create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.9));
  db.upsert_collabs_embeddings(&ws1, &oid, vec![frag.clone()])
    .await?;
  let frag2 = create_test_fragment(&oid, 0, generate_embedding_with_size(768, -0.9));
  db.upsert_collabs_embeddings(&ws2, &oid, vec![frag2.clone()])
    .await?;

  // Searching in ws1 should not return ws2's fragment
  let res1 = db
    .search(&ws1, &[], &generate_embedding_with_size(768, 0.9), 1)
    .await?;
  assert_eq!(res1.len(), 1);
  assert_eq!(res1[0].oid, Uuid::parse_str(&oid)?);

  // Searching in ws2 should not return ws1's fragment
  let res2 = db
    .search(&ws2, &[], &generate_embedding_with_size(768, -0.9), 1)
    .await?;
  assert_eq!(res2.len(), 1);
  assert_eq!(res2[0].oid, Uuid::parse_str(&oid)?);

  Ok(())
}

#[tokio::test]
async fn test_select_multiple_oids() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let ws = Uuid::new_v4().to_string();
  let oid1 = Uuid::new_v4().to_string();
  let oid2 = Uuid::new_v4().to_string();

  db.upsert_collabs_embeddings(
    &ws,
    &oid1,
    vec![create_test_fragment(
      &oid1,
      0,
      generate_embedding_with_size(768, 0.1),
    )],
  )
  .await?;
  db.upsert_collabs_embeddings(
    &ws,
    &oid2,
    vec![create_test_fragment(
      &oid2,
      0,
      generate_embedding_with_size(768, 0.2),
    )],
  )
  .await?;

  let map = db
    .select_collabs_fragment_ids(&[oid1.clone(), oid2.clone()])
    .await?;
  assert_eq!(map.len(), 2);
  assert!(map.contains_key(&Uuid::parse_str(&oid1)?));
  assert!(map.contains_key(&Uuid::parse_str(&oid2)?));
  assert_eq!(map[&Uuid::parse_str(&oid1)?].len(), 1);
  assert_eq!(map[&Uuid::parse_str(&oid2)?].len(), 1);

  Ok(())
}

#[tokio::test]
async fn test_skip_missing_content() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;

  let ws = Uuid::new_v4().to_string();
  let oid = Uuid::new_v4().to_string();

  // One fragment with no content (should be skipped), one with content
  let mut bad = create_test_fragment(&oid, 0, generate_embedding_with_size(768, 0.1));
  bad.content = None;
  let good = create_test_fragment(&oid, 1, generate_embedding_with_size(768, 0.2));

  db.upsert_collabs_embeddings(&ws, &oid, vec![bad, good.clone()])
    .await?;

  let map = db.select_collabs_fragment_ids(&[oid.clone()]).await?;
  let frags = &map[&Uuid::parse_str(&oid)?];
  assert_eq!(frags.len(), 1);
  assert_eq!(frags[0], good.fragment_id);

  Ok(())
}

#[tokio::test]
async fn test_object_ids_handling() -> Result<()> {
  let temp_dir = tempdir()?;
  let db = VectorSqliteDB::new(temp_dir.into_path())?;
  let workspace_id = Uuid::new_v4().to_string();

  // Test with different object ID formats
  let standard_oid = Uuid::new_v4().to_string();
  let special_oid = Uuid::new_v4().to_string(); // Zero UUID instead of empty
  let very_long_oid = Uuid::new_v4().to_string();

  // Insert fragments with different oids
  db.upsert_collabs_embeddings(
    &workspace_id,
    &standard_oid,
    vec![create_test_fragment(
      &standard_oid,
      0,
      generate_embedding_with_size(768, 0.1),
    )],
  )
  .await?;

  db.upsert_collabs_embeddings(
    &workspace_id,
    &special_oid,
    vec![create_test_fragment(
      &special_oid,
      0,
      generate_embedding_with_size(768, 0.2),
    )],
  )
  .await?;

  db.upsert_collabs_embeddings(
    &workspace_id,
    &very_long_oid,
    vec![create_test_fragment(
      &very_long_oid,
      0,
      generate_embedding_with_size(768, 0.3),
    )],
  )
  .await?;

  // Verify we can retrieve all three types of object IDs
  let all_oids = [
    standard_oid.clone(),
    special_oid.clone(),
    very_long_oid.clone(),
  ];
  let result = db.select_collabs_fragment_ids(&all_oids).await?;

  assert_eq!(
    result.len(),
    3,
    "Should retrieve fragments for all three object IDs"
  );
  assert!(result.contains_key(&Uuid::parse_str(&standard_oid)?));
  assert!(result.contains_key(&Uuid::parse_str(&special_oid)?));
  assert!(result.contains_key(&Uuid::parse_str(&very_long_oid)?));

  // Test search functionality works with different object IDs
  let search_results = db
    .search(
      &workspace_id,
      &[],
      &generate_embedding_with_size(768, 0.2),
      10,
    )
    .await?;

  // Verify we can find results for our special UUID
  let found_special_id = search_results
    .iter()
    .any(|r| r.content == "Content for fragment 0" && r.oid.to_string() == special_oid);

  assert!(
    found_special_id,
    "Should find the fragment with special UUID"
  );

  Ok(())
}

fn generate_embedding_with_size(size: usize, value: f32) -> Vec<f32> {
  vec![value; size]
}

fn create_test_fragment(oid: &str, index: i32, embeddings: Vec<f32>) -> EmbeddedChunk {
  let fragment_id = format!("fragment_{}", index);

  EmbeddedChunk {
    fragment_id,
    object_id: oid.to_string(),
    content_type: 1,
    content: Some(format!("Content for fragment {}", index)),
    metadata: Some(format!("Metadata for fragment {}", index)),
    fragment_index: index,
    embedder_type: 1,
    embeddings: Some(embeddings),
  }
}
