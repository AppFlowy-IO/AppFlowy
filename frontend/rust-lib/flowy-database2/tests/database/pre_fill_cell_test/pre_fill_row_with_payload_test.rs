use crate::database::pre_fill_cell_test::script::DatabasePreFillRowCellTest;
use collab_database::fields::date_type_option::DateCellData;
use collab_database::fields::select_type_option::SELECTION_IDS_SEPARATOR;
use flowy_database2::entities::{CreateRowPayloadPB, FieldType};
use std::collections::HashMap;

#[tokio::test]
async fn row_data_payload_with_empty_hashmap_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::new(),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(text_field.id.clone(), index, false)
    .await;
  test
    .assert_cell_content(text_field.id, index, "".to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_unknown_field_id_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;
  let malformed_field_id = "this_field_id_will_never_exist";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(
        malformed_field_id.to_string(),
        "sample cell data".to_string(),
      )]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(text_field.id.clone(), index, false)
    .await;
  test
    .assert_cell_content(text_field.id.clone(), index, "".to_string())
    .await;
  test
    .assert_cell_existence(malformed_field_id.to_string(), index, false)
    .await;
}

#[tokio::test]
async fn row_data_payload_with_empty_string_text_data_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;
  let cell_data = "";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(text_field.id.clone(), cell_data.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(text_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(text_field.id, index, cell_data.to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_text_data_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;
  let cell_data = "sample cell data";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(text_field.id.clone(), cell_data.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(text_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(text_field.id.clone(), index, cell_data.to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_multi_text_data_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;
  let number_field = test.get_first_field(FieldType::Number).await;
  let url_field = test.get_first_field(FieldType::URL).await;

  let text_cell_data = "sample cell data";
  let number_cell_data = "1234";
  let url_cell_data = "appflowy.io";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([
        (text_field.id.clone(), text_cell_data.to_string()),
        (number_field.id.clone(), number_cell_data.to_string()),
        (url_field.id.clone(), url_cell_data.to_string()),
      ]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(text_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(text_field.id, index, text_cell_data.to_string())
    .await;
  test
    .assert_cell_existence(number_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(number_field.id, index, "$1,234".to_string())
    .await;
  test
    .assert_cell_existence(url_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(url_field.id, index, url_cell_data.to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_date_time_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime).await;
  let cell_data = "1710510086";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(date_field.id.clone(), cell_data.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(date_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(date_field.id.clone(), index, "2024/03/15".to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_invalid_date_time_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime).await;
  let cell_data = DateCellData {
    timestamp: Some(1710510086),
    ..Default::default()
  }
  .to_string();

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(date_field.id.clone(), cell_data.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(date_field.id.clone(), index, false)
    .await;
}

#[tokio::test]
async fn row_data_payload_with_checkbox_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;
  let cell_data = "Yes";

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(checkbox_field.id.clone(), cell_data.to_string())]),
      ..Default::default()
    })
    .await;
  let index = test.rows.len() - 1;
  test.wait(100).await;
  test
    .assert_cell_existence(checkbox_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(checkbox_field.id.clone(), index, cell_data.to_string())
    .await;
}

#[tokio::test]
async fn row_data_payload_with_select_option_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let multi_select_field = test.get_first_field(FieldType::MultiSelect).await;
  let options = test
    .get_multi_select_type_option(&multi_select_field.id)
    .await;

  let ids = options
    .iter()
    .map(|option| option.id.clone())
    .collect::<Vec<_>>()
    .join(SELECTION_IDS_SEPARATOR);

  let stringified_cell_data = options
    .iter()
    .map(|option| option.name.clone())
    .collect::<Vec<_>>()
    .join(SELECTION_IDS_SEPARATOR);

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(multi_select_field.id.clone(), ids)]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(multi_select_field.id.clone(), index, true)
    .await;
  test
    .assert_cell_content(multi_select_field.id.clone(), index, stringified_cell_data)
    .await;
}

#[tokio::test]
async fn row_data_payload_with_invalid_select_option_id_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let multi_select_field = test.get_first_field(FieldType::MultiSelect).await;
  let mut options = test
    .get_multi_select_type_option(&multi_select_field.id)
    .await;

  let first_id = options.swap_remove(0).id;
  let ids = [first_id.clone(), "nonsense".to_string()].join(SELECTION_IDS_SEPARATOR);

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(multi_select_field.id.clone(), ids.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(multi_select_field.id.clone(), index, true)
    .await;
  test
    .assert_select_option_cell_strict(multi_select_field.id.clone(), index, first_id)
    .await;
}

#[tokio::test]
async fn row_data_payload_with_too_many_select_option_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;
  let single_select_field = test.get_first_field(FieldType::SingleSelect).await;
  let mut options = test
    .get_single_select_type_option(&single_select_field.id)
    .await;

  let ids = options
    .iter()
    .map(|option| option.id.clone())
    .collect::<Vec<_>>()
    .join(SELECTION_IDS_SEPARATOR);

  let stringified_cell_data = options.swap_remove(0).id;

  test
    .create_row_with_payload(CreateRowPayloadPB {
      view_id: test.view_id.clone(),
      data: HashMap::from([(single_select_field.id.clone(), ids.to_string())]),
      ..Default::default()
    })
    .await;

  test.wait(100).await;
  let index = test.rows.len() - 1;
  test
    .assert_cell_existence(single_select_field.id.clone(), index, true)
    .await;
  test
    .assert_select_option_cell_strict(single_select_field.id.clone(), index, stringified_cell_data)
    .await;
}
