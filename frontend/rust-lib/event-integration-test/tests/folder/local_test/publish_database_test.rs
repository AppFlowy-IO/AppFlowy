use std::collections::HashMap;

use collab_folder::ViewLayout;
use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::{
  ImportPayloadPB, ImportTypePB, ImportValuePayloadPB, ViewLayoutPB, ViewPB,
};
use flowy_folder::view_operation::EncodedCollabWrapper;

use crate::util::unzip;

#[tokio::test]
async fn publish_single_database_test() {
  let test = EventIntegrationTest::new_anon().await;
  test.sign_up_as_anon().await;

  // import a csv file and try to get its publish collab
  let grid = import_csv("publish_grid_primary.csv", &test).await;

  let grid_encoded_collab = test
    .get_encoded_collab_v1_from_disk(&grid.id, ViewLayout::Grid)
    .await;

  match grid_encoded_collab {
    EncodedCollabWrapper::Database(encoded_collab) => {
      // the len of row collabs should be the same as the number of rows in the csv file
      let rows_len = encoded_collab.database_row_encoded_collabs.len();
      assert_eq!(rows_len, 18);
    },
    _ => panic!("Expected database collab"),
  }
}

#[tokio::test]
async fn publish_databases_from_existing_workspace() {
  let test = EventIntegrationTest::new_anon().await;
  test.sign_up_as_anon().await;

  // import a workspace
  // there's a sample screenshot of the workspace in the asset folder,
  //  unzip it and check the views if needed
  let _ = import_workspace("064_database_publish", &test).await;

  let publish_database_set = test.get_all_views().await;

  let publish_grid_set = publish_database_set
    .iter()
    // there're 8 built-in grids in the workspace with the name starting with "publish grid"
    .filter(|view| view.layout == ViewLayoutPB::Grid && view.name.starts_with("publish grid"))
    .collect::<Vec<_>>();

  let publish_calendar_set = publish_database_set
    .iter()
    // there's 1 built-in calender in the workspace with the name starting with "publish calendar"
    .filter(|view| view.layout == ViewLayoutPB::Calendar && view.name.starts_with("publish calendar"))
    .collect::<Vec<_>>();

  let publish_board_set = publish_database_set
    .iter()
    // there's 1 built-in board in the workspace with the name starting with "publish board"
    .filter(|view| view.layout == ViewLayoutPB::Board && view.name.starts_with("publish board"))
    .collect::<Vec<_>>();

  let mut expectations: HashMap<&str, usize> = HashMap::new();
  // grid
  // 5 rows
  expectations.insert("publish grid (deprecated)", 5);

  // the following 7 grids are the same, just with different filters or sorting or layout
  // to check if the collab is correctly generated
  // 18 rows
  expectations.insert("publish grid", 18);
  // 18 rows
  expectations.insert("publish grid (with board)", 18);
  // 18 rows
  expectations.insert("publish grid (with calendar)", 18);
  // 18 rows
  expectations.insert("publish grid (with grid)", 18);
  // 18 rows
  expectations.insert("publish grid (filtered)", 18);
  // 18 rows
  expectations.insert("publish grid (sorted)", 18);

  // calendar
  expectations.insert("publish calendar", 2);

  // board
  expectations.insert("publish board", 15);

  test_publish_encode_collab_result(&test, publish_grid_set, expectations.clone()).await;

  test_publish_encode_collab_result(&test, publish_calendar_set, expectations.clone()).await;

  test_publish_encode_collab_result(&test, publish_board_set, expectations.clone()).await;
}

async fn test_publish_encode_collab_result(
  test: &EventIntegrationTest,
  views: Vec<&ViewPB>,
  expectations: HashMap<&str, usize>,
) {
  for view in views {
    let id = view.id.clone();
    let layout = view.layout.clone();

    test.open_database(&id).await;

    let encoded_collab = test
      .get_encoded_collab_v1_from_disk(&id, layout.into())
      .await;

    match encoded_collab {
      EncodedCollabWrapper::Database(encoded_collab) => {
        if let Some(rows_len) = expectations.get(&view.name.as_str()) {
          assert_eq!(encoded_collab.database_row_encoded_collabs.len(), *rows_len);
        }
      },
      _ => panic!("Expected database collab"),
    }
  }
}

async fn import_workspace(file_name: &str, test: &EventIntegrationTest) -> Vec<ViewPB> {
  let (cleaner, file_path) = unzip("./tests/asset", file_name).unwrap();
  test
    .import_appflowy_data(file_path.to_str().unwrap().to_string(), None)
    .await
    .unwrap();
  let views = test.get_all_workspace_views().await;
  drop(cleaner);
  views
}

async fn import_csv(file_name: &str, test: &EventIntegrationTest) -> ViewPB {
  let (cleaner, file_path) = unzip("./tests/asset", file_name).unwrap();
  let csv_string = std::fs::read_to_string(file_path).unwrap();
  let workspace_id = test.get_current_workspace().await.id;
  let import_data = gen_import_data(file_name.to_string(), csv_string, workspace_id);
  let views = test.import_data(import_data).await;
  drop(cleaner);
  views[0].clone()
}

fn gen_import_data(file_name: String, csv_string: String, workspace_id: String) -> ImportPayloadPB {
  ImportPayloadPB {
    parent_view_id: workspace_id.clone(),
    sync_after_create: false,
    values: vec![ImportValuePayloadPB {
      name: file_name,
      data: Some(csv_string.as_bytes().to_vec()),
      file_path: None,
      view_layout: ViewLayoutPB::Grid,
      import_type: ImportTypePB::CSV,
    }],
  }
}
