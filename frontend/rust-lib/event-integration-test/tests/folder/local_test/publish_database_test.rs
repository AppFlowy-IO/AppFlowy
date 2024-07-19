use collab_folder::ViewLayout;
use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::{
  ImportPayloadPB, ImportTypePB, ImportValuePayloadPB, ViewLayoutPB, ViewPB,
};
use flowy_folder::publish_util::generate_publish_name;
use flowy_folder::view_operation::EncodedCollabWrapper;
use flowy_folder_pub::entities::{
  PublishDocumentPayload, PublishPayload, PublishViewInfo, PublishViewMeta, PublishViewMetaData,
};

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

async fn import_csv(file_name: &str, test: &EventIntegrationTest) -> ViewPB {
  let (cleaner, file_path) = unzip("./tests/asset", &file_name).unwrap();
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
