use crate::database::database_ref_test::script::DatabaseRefScript::*;
use crate::database::database_ref_test::script::DatabaseRefTest;

#[tokio::test]
async fn database_ref_number_of_database_test() {
  let mut test = DatabaseRefTest::new().await;
  test
    .run_scripts(vec![
      AssertNumberOfDatabase { expected: 1 },
      CreateNewGrid,
      AssertNumberOfDatabase { expected: 2 },
    ])
    .await;
}

#[tokio::test]
async fn database_ref_link_with_existing_database_test() {
  let mut test = DatabaseRefTest::new().await;
  let database = test.all_databases().await.pop().unwrap();
  test
    .run_scripts(vec![
      LinkGridToDatabase {
        database_id: database.database_id,
      },
      AssertNumberOfDatabase { expected: 1 },
    ])
    .await;
}

#[tokio::test]
async fn database_ref_link_with_existing_database_row_test() {
  let mut test = DatabaseRefTest::new().await;
  let database = test.all_databases().await.pop().unwrap();
  test
    .run_scripts(vec![
      LinkGridToDatabase {
        database_id: database.database_id,
      },
      AssertNumberOfDatabase { expected: 1 },
    ])
    .await;
}

#[tokio::test]
async fn database_ref_create_new_row_test() {
  let mut test = DatabaseRefTest::new().await;
  let database = test.all_databases().await.pop().unwrap();
  let database_views = test.all_database_ref_views(&database.database_id).await;
  assert_eq!(database_views.len(), 1);
  let view_id_1 = database_views.get(0).unwrap().view_id.clone();
  test
    .run_scripts(vec![
      AssertNumberOfRows {
        view_id: view_id_1.clone(),
        expected: 6,
      },
      LinkGridToDatabase {
        database_id: database.database_id.clone(),
      },
      AssertNumberOfDatabase { expected: 1 },
    ])
    .await;

  let database_views = test.all_database_ref_views(&database.database_id).await;
  assert_eq!(database_views.len(), 2);
  let view_id_1 = database_views.get(0).unwrap().view_id.clone();
  let view_id_2 = database_views.get(1).unwrap().view_id.clone();

  // Create a new row
  let mut builder = test.row_builder(&view_id_1).await;
  builder.insert_text_cell("hello world");

  test
    .run_scripts(vec![
      CreateRow {
        view_id: view_id_1.clone(),
        row_rev: builder.build(),
      },
      AssertNumberOfRows {
        view_id: view_id_1,
        expected: 7,
      },
      AssertNumberOfRows {
        view_id: view_id_2,
        expected: 7,
      },
    ])
    .await;
}
