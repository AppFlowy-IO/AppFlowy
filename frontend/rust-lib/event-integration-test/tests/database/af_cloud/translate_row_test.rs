use crate::database::af_cloud::util::make_test_summary_grid;
use std::time::Duration;
use tokio::time::sleep;

use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_database2::entities::{FieldType, TranslateRowPB};

#[tokio::test]
async fn af_cloud_translate_row_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  // create document and then insert content
  let current_workspace = test.get_current_workspace().await;
  let initial_data = make_test_summary_grid().to_json_bytes().unwrap();
  let view = test
    .create_grid(
      &current_workspace.id,
      "translate database".to_string(),
      initial_data,
    )
    .await;

  let database_pb = test.get_database(&view.id).await;
  let field = test
    .get_all_database_fields(&view.id)
    .await
    .items
    .into_iter()
    .find(|field| field.field_type == FieldType::Translate)
    .unwrap();

  let row_id = database_pb.rows[0].id.clone();
  let data = TranslateRowPB {
    view_id: view.id.clone(),
    row_id: row_id.clone(),
    field_id: field.id.clone(),
  };
  test.translate_row(data).await;

  sleep(Duration::from_secs(1)).await;
  let cell = test
    .get_text_cell(&view.id, &row_id, &field.id)
    .await
    .to_lowercase();
  println!("cell: {}", cell);
  // default translation is in French. So it should be something like this:
  // Prix:2,6 $,Nom du produit:Pomme,Statut:TERMINÉ
  assert!(cell.contains("pomme"));
  assert!(cell.contains("produit"));
  assert!(cell.contains("prix"));
}
