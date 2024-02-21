// TODO: Delete file or rewrite to use abstract tantivy implementation
// use diesel::QueryResult;
// use diesel_migrations::MigrationHarness;
// use flowy_search::native::sqlite_search::{
//   create_index, delete_document, delete_view, search_index, update_document, update_index,
//   SearchData,
// };
// use flowy_sqlite::{Database, PoolConfig, DB_NAME, MIGRATIONS};
// use tempfile::TempDir;

// fn setup_db() -> (TempDir, Database) {
//   let tempdir = TempDir::new().unwrap();
//   let path = tempdir.path().to_str().unwrap();
//   let pool_config = PoolConfig::default();
//   let database = Database::new(path, DB_NAME, pool_config).unwrap();
//   let mut conn = database.get_connection().unwrap();
//   (*conn).run_pending_migrations(MIGRATIONS).unwrap();

//   (tempdir, database)
// }

// #[test]
// fn test_view_search() -> QueryResult<()> {
//   let (_tempdir, database) = setup_db();
//   let mut conn = database.get_connection().unwrap();

//   // add views we will try to match
//   let first = SearchData::new_view("asdf", "First doc");
//   let second = SearchData::new_view("qwer", "Second doc");
//   create_index(&mut conn, &first).unwrap();
//   create_index(&mut conn, &second).unwrap();

//   // add views that should not match
//   let unrelated = SearchData::new_view("zxcv", "unrelated");
//   create_index(&mut conn, &unrelated).unwrap();

//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.contains(&first));
//   assert!(results.contains(&second));

//   // remove views
//   delete_view(&mut conn, &first.view_id).unwrap();
//   delete_view(&mut conn, &second.view_id).unwrap();
//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.is_empty());

//   Ok(())
// }

// #[test]
// fn test_view_search_limit() -> QueryResult<()> {
//   let (_tempdir, database) = setup_db();
//   let mut conn = database.get_connection().unwrap();

//   // add views we will try to match
//   let first = SearchData::new_view("asdf", "First doc");
//   let second = SearchData::new_view("qwer", "Second doc");
//   create_index(&mut conn, &first).unwrap();
//   create_index(&mut conn, &second).unwrap();

//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.len() == 2);

//   let results = search_index(&mut conn, "doc", Some(1)).unwrap();
//   assert!(results.len() == 1);

//   Ok(())
// }

// #[test]
// fn test_view_update() -> QueryResult<()> {
//   let (_tempdir, database) = setup_db();
//   let mut conn = database.get_connection().unwrap();

//   // add views we will try to match
//   let view = SearchData::new_view("asdf", "First doc");
//   create_index(&mut conn, &view).unwrap();

//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.contains(&view));

//   // update view title
//   let view = SearchData {
//     data: "new title".to_owned(),
//     ..view
//   };
//   update_index(&mut conn, &view).unwrap();
//   // prev search
//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.is_empty());

//   // updated search
//   let results = search_index(&mut conn, "new", None).unwrap();
//   assert!(results.contains(&view));

//   Ok(())
// }

// #[test]
// fn test_doc_search() -> QueryResult<()> {
//   let (_tempdir, database) = setup_db();
//   let mut conn = database.get_connection().unwrap();

//   // add docs we will try to match
//   let first = SearchData::new_document("asdf", "123", "First doc");
//   let second = SearchData::new_document("qwer", "456", "Second doc");
//   create_index(&mut conn, &first).unwrap();
//   create_index(&mut conn, &second).unwrap();

//   // add docs that should not match
//   let unrelated = SearchData::new_document("zxcv", "987", "unrelated");
//   create_index(&mut conn, &unrelated).unwrap();

//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.contains(&first));
//   assert!(results.contains(&second));

//   // remove doc using page_id
//   delete_document(&mut conn, &first.id).unwrap();
//   // remove doc using view_id
//   delete_view(&mut conn, &second.view_id).unwrap();
//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.is_empty());

//   Ok(())
// }

// #[test]
// fn test_doc_update() -> QueryResult<()> {
//   let (_tempdir, database) = setup_db();
//   let mut conn = database.get_connection().unwrap();

//   // add docs we will try to match
//   let doc = SearchData::new_document("asdf", "123", "First doc");
//   create_index(&mut conn, &doc).unwrap();

//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.contains(&doc));

//   // update doc content
//   let doc = SearchData {
//     data: "new content".to_owned(),
//     ..doc
//   };
//   update_document(&mut conn, &doc).unwrap();
//   // prev search
//   let results = search_index(&mut conn, "doc", None).unwrap();
//   assert!(results.is_empty());

//   // updated search
//   let results = search_index(&mut conn, "new", None).unwrap();
//   assert!(results.contains(&doc));

//   Ok(())
// }
