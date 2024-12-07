use crate::util::unzip;
use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use std::time::Duration;

#[tokio::test]
async fn import_appflowy_data_folder_into_new_view_test() {
  let import_container_name = "040_local".to_string();
  let user_db_path = unzip("./tests/asset", &import_container_name).unwrap();
  let imported_af_data_path = unzip("./tests/asset", &import_container_name).unwrap();

  use_localhost_af_cloud().await;
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path.clone(), DEFAULT_NAME.to_string())
      .await;
  // In the 040_local, the structure is:
  // workspace:
  //  view: Document1
  //    view: Document2
  //      view: Grid1
  //      view: Grid2
  // Sleep for 2 seconds to wait for the initial workspace to be created
  tokio::time::sleep(Duration::from_secs(5)).await;

  test
    .import_appflowy_data(
      imported_af_data_path.to_str().unwrap().to_string(),
      Some(import_container_name.clone()),
    )
    .await
    .unwrap();

  // after import, the structure is:
  // workspace:
  //    Document1
  //     Document2
  //        Grid1
  //        Grid2
  //     040_local
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 1);
  assert_eq!(views[0].name, "Document1");
  assert_eq!(views[0].child_views.len(), 2);

  for (index, view) in views[0].child_views.iter().enumerate() {
    let view = test.get_view(&view.id).await;
    if index == 1 {
      assert_eq!(view.name, import_container_name);
    }
  }
}
