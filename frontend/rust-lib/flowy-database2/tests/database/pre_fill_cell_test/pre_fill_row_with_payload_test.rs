use std::collections::HashMap;

use flowy_database2::entities::{CreateRowPayloadPB, FieldType};
use flowy_database2::services::field::{DateCellData, SELECTION_IDS_SEPARATOR};

use crate::database::pre_fill_cell_test::script::{
  DatabasePreFillRowCellTest, PreFillRowCellTestScript::*,
};

// This suite of tests cover creating a row using `CreateRowPayloadPB` that passes
// in some cell data in its `data` field of `HashMap<String, String>` which is a
// map of `field_id` to its corresponding cell data as a String. If valid, the cell
// data will be pre-filled into the row's cells before creating it in collab.

#[tokio::test]
async fn row_data_payload_with_empty_hashmap_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText).await;

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::new(),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),
      exists: false,
    },
    AssertCellContent {
      field_id: text_field.id,
      row_index: test.row_details.len(),

      expected_content: "".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn row_data_payload_with_unknown_field_id_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText).await;
  let malformed_field_id = "this_field_id_will_never_exist";

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(
          malformed_field_id.to_string(),
          "sample cell data".to_string(),
        )]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),
      exists: false,
    },
    AssertCellContent {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),

      expected_content: "".to_string(),
    },
    AssertCellExistence {
      field_id: malformed_field_id.to_string(),
      row_index: test.row_details.len(),
      exists: false,
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn row_data_payload_with_empty_string_text_data_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText).await;
  let cell_data = "";

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(text_field.id.clone(), cell_data.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: text_field.id,
      row_index: test.row_details.len(),

      expected_content: cell_data.to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn row_data_payload_with_text_data_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText).await;
  let cell_data = "sample cell data";

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(text_field.id.clone(), cell_data.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),

      expected_content: cell_data.to_string(),
    },
  ];

  test.run_scripts(scripts).await;
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

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([
          (text_field.id.clone(), text_cell_data.to_string()),
          (number_field.id.clone(), number_cell_data.to_string()),
          (url_field.id.clone(), url_cell_data.to_string()),
        ]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: text_field.id,
      row_index: test.row_details.len(),

      expected_content: text_cell_data.to_string(),
    },
    AssertCellExistence {
      field_id: number_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: number_field.id,
      row_index: test.row_details.len(),

      expected_content: "$1,234".to_string(),
    },
    AssertCellExistence {
      field_id: url_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: url_field.id,
      row_index: test.row_details.len(),

      expected_content: url_cell_data.to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn row_data_payload_with_date_time_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let date_field = test.get_first_field(FieldType::DateTime).await;
  let cell_data = "1710510086";

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(date_field.id.clone(), cell_data.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: date_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: date_field.id.clone(),
      row_index: test.row_details.len(),

      expected_content: "2024/03/15".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
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

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(date_field.id.clone(), cell_data.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: date_field.id.clone(),
      row_index: test.row_details.len(),
      exists: false,
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn row_data_payload_with_checkbox_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;
  let cell_data = "Yes";

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(checkbox_field.id.clone(), cell_data.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: checkbox_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: checkbox_field.id.clone(),
      row_index: test.row_details.len(),

      expected_content: cell_data.to_string(),
    },
  ];

  test.run_scripts(scripts).await;
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

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(multi_select_field.id.clone(), ids)]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: multi_select_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertCellContent {
      field_id: multi_select_field.id.clone(),
      row_index: test.row_details.len(),

      expected_content: stringified_cell_data,
    },
  ];

  test.run_scripts(scripts).await;
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

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(multi_select_field.id.clone(), ids.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: multi_select_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertSelectOptionCellStrict {
      field_id: multi_select_field.id.clone(),
      row_index: test.row_details.len(),
      expected_content: first_id,
    },
  ];

  test.run_scripts(scripts).await;
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

  let scripts = vec![
    CreateRowWithPayload {
      payload: CreateRowPayloadPB {
        view_id: test.view_id.clone(),
        data: HashMap::from([(single_select_field.id.clone(), ids.to_string())]),
        ..Default::default()
      },
    },
    Wait { milliseconds: 100 },
    AssertCellExistence {
      field_id: single_select_field.id.clone(),
      row_index: test.row_details.len(),
      exists: true,
    },
    AssertSelectOptionCellStrict {
      field_id: single_select_field.id.clone(),
      row_index: test.row_details.len(),
      expected_content: stringified_cell_data,
    },
  ];

  test.run_scripts(scripts).await;
}
