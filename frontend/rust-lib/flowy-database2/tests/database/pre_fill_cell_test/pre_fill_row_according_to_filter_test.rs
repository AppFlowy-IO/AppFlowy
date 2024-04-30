use flowy_database2::entities::{
  CheckboxFilterConditionPB, CheckboxFilterPB, DateFilterConditionPB, DateFilterPB, FieldType,
  FilterDataPB, SelectOptionFilterConditionPB, SelectOptionFilterPB, TextFilterConditionPB,
  TextFilterPB,
};
use flowy_database2::services::field::SELECTION_IDS_SEPARATOR;

use crate::database::pre_fill_cell_test::script::{
  DatabasePreFillRowCellTest, PreFillRowCellTestScript::*,
};

// This suite of tests cover creating an empty row into a database that has
// active filters. Where appropriate, the row's cell data will be pre-filled
// into the row's cells before creating it in collab.

#[tokio::test]
async fn according_to_text_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText);

  let scripts = vec![
    InsertFilter {
      filter: FilterDataPB {
        field_id: text_field.id.clone(),
        field_type: FieldType::RichText,
        data: TextFilterPB {
          condition: TextFilterConditionPB::TextContains,
          content: "sample".to_string(),
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    CreateEmptyRow,
    Wait { milliseconds: 100 },
  ];

  test.run_scripts(scripts).await;

  let scripts = vec![
    AssertCellExistence {
      field_id: text_field.id.clone(),
      row_index: test.row_details.len() - 1,
      exists: true,
    },
    AssertCellContent {
      field_id: text_field.id,
      row_index: test.row_details.len() - 1,

      expected_content: "sample".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_empty_text_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText);

  let scripts = vec![
    InsertFilter {
      filter: FilterDataPB {
        field_id: text_field.id.clone(),
        field_type: FieldType::RichText,
        data: TextFilterPB {
          condition: TextFilterConditionPB::TextContains,
          content: "".to_string(),
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    CreateEmptyRow,
    Wait { milliseconds: 100 },
  ];

  test.run_scripts(scripts).await;

  let scripts = vec![AssertCellExistence {
    field_id: text_field.id.clone(),
    row_index: test.row_details.len() - 1,
    exists: false,
  }];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_text_is_not_empty_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let text_field = test.get_first_field(FieldType::RichText);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: text_field.id.clone(),
        field_type: FieldType::RichText,
        data: TextFilterPB {
          condition: TextFilterConditionPB::TextIsNotEmpty,
          content: "".to_string(),
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(6),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(6),
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_checkbox_is_unchecked_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let checkbox_field = test.get_first_field(FieldType::Checkbox);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: checkbox_field.id.clone(),
        field_type: FieldType::Checkbox,
        data: CheckboxFilterPB {
          condition: CheckboxFilterConditionPB::IsUnChecked,
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(4),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(5),
  ];

  test.run_scripts(scripts).await;

  let scripts = vec![AssertCellExistence {
    field_id: checkbox_field.id.clone(),
    row_index: 4,
    exists: false,
  }];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_checkbox_is_checked_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let checkbox_field = test.get_first_field(FieldType::Checkbox);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: checkbox_field.id.clone(),
        field_type: FieldType::Checkbox,
        data: CheckboxFilterPB {
          condition: CheckboxFilterConditionPB::IsChecked,
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(3),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(4),
  ];

  test.run_scripts(scripts).await;

  let scripts = vec![
    AssertCellExistence {
      field_id: checkbox_field.id.clone(),
      row_index: 3,
      exists: true,
    },
    AssertCellContent {
      field_id: checkbox_field.id,
      row_index: 3,

      expected_content: "Yes".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_date_time_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let datetime_field = test.get_first_field(FieldType::DateTime);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: datetime_field.id.clone(),
        field_type: FieldType::DateTime,
        data: DateFilterPB {
          condition: DateFilterConditionPB::DateIs,
          timestamp: Some(1710510086),
          ..Default::default()
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(0),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(1),
  ];

  test.run_scripts(scripts).await;

  let scripts = vec![
    AssertCellExistence {
      field_id: datetime_field.id.clone(),
      row_index: 0,
      exists: true,
    },
    AssertCellContent {
      field_id: datetime_field.id,
      row_index: 0,

      expected_content: "2024/03/15".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_invalid_date_time_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let datetime_field = test.get_first_field(FieldType::DateTime);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: datetime_field.id.clone(),
        field_type: FieldType::DateTime,
        data: DateFilterPB {
          condition: DateFilterConditionPB::DateIs,
          timestamp: None,
          ..Default::default()
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(7),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(8),
    AssertCellExistence {
      field_id: datetime_field.id.clone(),
      row_index: test.row_details.len(),
      exists: false,
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_select_option_is_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let multi_select_field = test.get_first_field(FieldType::MultiSelect);
  let options = test.get_multi_select_type_option(&multi_select_field.id);

  let filtering_options = [options[1].clone(), options[2].clone()];
  let ids = filtering_options
    .iter()
    .map(|option| option.id.clone())
    .collect();
  let stringified_expected = filtering_options
    .iter()
    .map(|option| option.name.clone())
    .collect::<Vec<_>>()
    .join(SELECTION_IDS_SEPARATOR);

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: multi_select_field.id.clone(),
        field_type: FieldType::MultiSelect,
        data: SelectOptionFilterPB {
          condition: SelectOptionFilterConditionPB::OptionIs,
          option_ids: ids,
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(1),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(2),
    AssertCellExistence {
      field_id: multi_select_field.id.clone(),
      row_index: 1,
      exists: true,
    },
    AssertCellContent {
      field_id: multi_select_field.id,
      row_index: 1,

      expected_content: stringified_expected,
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_select_option_contains_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let multi_select_field = test.get_first_field(FieldType::MultiSelect);
  let options = test.get_multi_select_type_option(&multi_select_field.id);

  let filtering_options = [options[1].clone(), options[2].clone()];
  let ids = filtering_options
    .iter()
    .map(|option| option.id.clone())
    .collect();
  let stringified_expected = filtering_options.first().unwrap().name.clone();

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: multi_select_field.id.clone(),
        field_type: FieldType::MultiSelect,
        data: SelectOptionFilterPB {
          condition: SelectOptionFilterConditionPB::OptionContains,
          option_ids: ids,
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(5),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(6),
    AssertCellExistence {
      field_id: multi_select_field.id.clone(),
      row_index: 5,
      exists: true,
    },
    AssertCellContent {
      field_id: multi_select_field.id,
      row_index: 5,

      expected_content: stringified_expected,
    },
  ];

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn according_to_select_option_is_not_empty_filter_test() {
  let mut test = DatabasePreFillRowCellTest::new().await;

  let multi_select_field = test.get_first_field(FieldType::MultiSelect);
  let options = test.get_multi_select_type_option(&multi_select_field.id);

  let stringified_expected = options.first().unwrap().name.clone();

  let scripts = vec![
    AssertRowCount(7),
    InsertFilter {
      filter: FilterDataPB {
        field_id: multi_select_field.id.clone(),
        field_type: FieldType::MultiSelect,
        data: SelectOptionFilterPB {
          condition: SelectOptionFilterConditionPB::OptionIsNotEmpty,
          ..Default::default()
        }
        .try_into()
        .unwrap(),
      },
    },
    Wait { milliseconds: 100 },
    AssertRowCount(5),
    CreateEmptyRow,
    Wait { milliseconds: 100 },
    AssertRowCount(6),
    AssertCellExistence {
      field_id: multi_select_field.id.clone(),
      row_index: 5,
      exists: true,
    },
    AssertCellContent {
      field_id: multi_select_field.id,
      row_index: 5,

      expected_content: stringified_expected,
    },
  ];

  test.run_scripts(scripts).await;
}
