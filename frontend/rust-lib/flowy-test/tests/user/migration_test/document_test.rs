use flowy_core::DEFAULT_NAME;
use flowy_folder2::entities::ViewLayoutPB;
use flowy_test::FlowyCoreTest;

use crate::user::migration_test::util::unzip_history_user_db;

#[tokio::test]
async fn migrate_historical_empty_document_test() {
  let (cleaner, user_db_path) = unzip_history_user_db("historical_empty_document").unwrap();
  let test = FlowyCoreTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string());

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  for view in views {
    assert_eq!(view.layout, ViewLayoutPB::Document);
    let doc = test.open_document(view.id).await;
    println!("doc: {:?}", doc.data);
  }

  drop(cleaner);
}
