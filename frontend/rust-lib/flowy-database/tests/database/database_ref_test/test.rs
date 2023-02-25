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
