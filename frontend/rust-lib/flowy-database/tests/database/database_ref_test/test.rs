use crate::database::database_ref_test::script::LinkDatabaseTest;
use crate::database::database_ref_test::script::LinkDatabaseTestScript::*;

#[tokio::test]
async fn number_of_database_test() {
  let mut test = LinkDatabaseTest::new().await;
  test
    .run_scripts(vec![
      // After the LinkDatabaseTest initialize, it will create a grid.
      AssertNumberOfDatabase { expected: 1 },
      CreateNewGrid,
      AssertNumberOfDatabase { expected: 2 },
    ])
    .await;
}

#[tokio::test]
async fn database_view_link_with_existing_database_test() {
  let mut test = LinkDatabaseTest::new().await;
  let database = test.all_databases().await.pop().unwrap();
  test
    .run_scripts(vec![
      CreateGridViewAndLinkToDatabase {
        database_id: database.database_id,
      },
      AssertNumberOfDatabase { expected: 1 },
    ])
    .await;
}

#[tokio::test]
async fn check_number_of_rows_in_linked_database_view() {
  let mut test = LinkDatabaseTest::new().await;
  let database = test.all_databases().await.pop().unwrap();
  let view = test
    .all_database_ref_views(&database.database_id)
    .await
    .remove(0);

  test
    .run_scripts(vec![
      CreateGridViewAndLinkToDatabase {
        database_id: database.database_id,
      },
      // The initial number of rows is 6
      AssertNumberOfRows {
        view_id: view.view_id.clone(),
        expected: 6,
      },
    ])
    .await;
}

#[tokio::test]
async fn multiple_views_share_database_rows() {
  let mut test = LinkDatabaseTest::new().await;

  // After the LinkDatabaseTest initialize, it will create a default database
  // with Grid layout.
  let database = test.all_databases().await.pop().unwrap();
  let mut database_views = test.all_database_ref_views(&database.database_id).await;
  assert_eq!(database_views.len(), 1);
  let view = database_views.remove(0);

  test
    .run_scripts(vec![
      AssertNumberOfRows {
        view_id: view.view_id.clone(),
        expected: 6,
      },
      CreateGridViewAndLinkToDatabase {
        database_id: database.database_id.clone(),
      },
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
      AssertNumberOfDatabase { expected: 1 },
    ])
    .await;
}
