use collab_database::database::gen_option_id;

use flowy_database2::entities::{FieldChangesetParams, FieldType};
use flowy_database2::services::field::{SelectOption, SingleSelectTypeOption, CHECK, UNCHECK};

use crate::database::field_test::script::DatabaseFieldTest;
use crate::database::field_test::script::FieldScript::*;
use crate::database::field_test::util::*;

#[tokio::test]
async fn grid_create_field() {
  let mut test = DatabaseFieldTest::new().await;
  let (params, field) = create_text_field(&test.view_id());

  let scripts = vec![
    CreateField { params },
    AssertFieldTypeOptionEqual {
      field_index: test.field_count(),
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;

  let (params, field) = create_single_select_field(&test.view_id());
  let scripts = vec![
    CreateField { params },
    AssertFieldTypeOptionEqual {
      field_index: test.field_count(),
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;

  let (params, field) = create_timestamp_field(&test.view_id(), FieldType::CreatedTime);
  let scripts = vec![
    CreateField { params },
    AssertFieldTypeOptionEqual {
      field_index: test.field_count(),
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;

  let (params, field) = create_time_field(&test.view_id());
  let scripts = vec![
    CreateField { params },
    AssertFieldTypeOptionEqual {
      field_index: test.field_count(),
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;

  let (params, field) = create_time_field(&test.view_id());
  let scripts = vec![
    CreateField { params },
    AssertFieldTypeOptionEqual {
      field_index: test.field_count(),
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_create_duplicate_field() {
  let mut test = DatabaseFieldTest::new().await;
  let (params, _) = create_text_field(&test.view_id());
  let field_count = test.field_count();
  let expected_field_count = field_count + 1;
  let scripts = vec![
    CreateField {
      params: params.clone(),
    },
    AssertFieldCount(expected_field_count),
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
  let mut test = DatabaseFieldTest::new().await;
  let (params, _) = create_single_select_field(&test.view_id());
  let create_field_index = test.field_count();
  let scripts = vec![CreateField { params }];
  test.run_scripts(scripts).await;

  let field = test.get_fields().await.pop().unwrap().clone();
  let changeset = FieldChangesetParams {
    field_id: field.id.clone(),
    view_id: test.view_id(),
    ..Default::default()
  };

  let scripts = vec![
    UpdateField { changeset },
    AssertFieldTypeOptionEqual {
      field_index: create_field_index,
      expected_type_option_data: field.get_any_type_option(field.field_type).unwrap(),
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_delete_field() {
  let mut test = DatabaseFieldTest::new().await;
  let original_field_count = test.field_count();
  let (params, _) = create_text_field(&test.view_id());
  let scripts = vec![CreateField { params }];
  test.run_scripts(scripts).await;

  let field = test.get_fields().await.pop().unwrap();
  let scripts = vec![
    DeleteField { field },
    AssertFieldCount(original_field_count),
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_switch_from_select_option_to_checkbox_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::SingleSelect).await;

  // Update the type option data of single select option
  let mut options = test.get_single_select_type_option(&field.id).await;
  options.clear();
  // Add a new option with name CHECK
  options.push(SelectOption {
    id: gen_option_id(),
    name: CHECK.to_string(),
    color: Default::default(),
  });
  // Add a new option with name UNCHECK
  options.push(SelectOption {
    id: gen_option_id(),
    name: UNCHECK.to_string(),
    color: Default::default(),
  });

  let scripts = vec![
    UpdateTypeOption {
      field_id: field.id.clone(),
      type_option: SingleSelectTypeOption {
        options,
        disable_color: false,
      }
      .into(),
    },
    SwitchToField {
      field_id: field.id.clone(),
      new_field_type: FieldType::Checkbox,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_switch_from_checkbox_to_select_option_test() {
  let mut test = DatabaseFieldTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await.clone();
  let scripts = vec![
    // switch to single-select field type
    SwitchToField {
      field_id: checkbox_field.id.clone(),
      new_field_type: FieldType::SingleSelect,
    },
    // Assert the cell content after switch the field type. The cell content will be changed if
    // the FieldType::SingleSelect implement the cell data TypeOptionTransform. Check out the
    // TypeOptionTransform trait for more information.
    //
    // Make sure which cell of the row you want to check.
    AssertCellContent {
      field_id: checkbox_field.id.clone(),
      // the mock data of the checkbox with row_index one is "true"
      row_index: 1,
      // The content of the checkbox should transform to the corresponding option name.
      expected_content: CHECK.to_string(),
    },
  ];
  test.run_scripts(scripts).await;

  let options = test.get_single_select_type_option(&checkbox_field.id).await;
  assert_eq!(options.len(), 2);
  assert!(options.iter().any(|option| option.name == UNCHECK));
  assert!(options.iter().any(|option| option.name == CHECK));
}

// Test when switching the current field from Multi-select to Text test
// The build-in test data is located in `make_test_grid` method(flowy-database/tests/grid_editor.rs).
// input:
//      option1, option2 -> "option1.name, option2.name"
#[tokio::test]
async fn grid_switch_from_multi_select_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::MultiSelect).await.clone();

  let multi_select_type_option = test.get_multi_select_type_option(&field_rev.id).await;

  let script_switch_field = vec![SwitchToField {
    field_id: field_rev.id.clone(),
    new_field_type: FieldType::RichText,
  }];

  test.run_scripts(script_switch_field).await;

  let script_assert_field = vec![AssertCellContent {
    field_id: field_rev.id.clone(),
    row_index: 0,
    expected_content: format!(
      "{},{}",
      multi_select_type_option.first().unwrap().name,
      multi_select_type_option.get(1).unwrap().name
    ),
  }];

  test.run_scripts(script_assert_field).await;
}

// Test when switching the current field from Checkbox to Text test
// input:
//      check -> "Yes"
//      unchecked -> "No"
#[tokio::test]
async fn grid_switch_from_checkbox_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::Checkbox).await;

  let scripts = vec![
    SwitchToField {
      field_id: field_rev.id.clone(),
      new_field_type: FieldType::RichText,
    },
    AssertCellContent {
      field_id: field_rev.id.clone(),
      row_index: 1,
      expected_content: "Yes".to_string(),
    },
    AssertCellContent {
      field_id: field_rev.id.clone(),
      row_index: 2,
      expected_content: "No".to_string(),
    },
  ];
  test.run_scripts(scripts).await;
}

// Test when switching the current field from Date to Text test
// input:
//      1647251762 -> Mar 14,2022 (This string will be different base on current data setting)
#[tokio::test]
async fn grid_switch_from_date_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::DateTime).await.clone();
  let scripts = vec![
    SwitchToField {
      field_id: field.id.clone(),
      new_field_type: FieldType::RichText,
    },
    AssertCellContent {
      field_id: field.id.clone(),
      row_index: 2,
      expected_content: "2022/03/14".to_string(),
    },
    AssertCellContent {
      field_id: field.id.clone(),
      row_index: 3,
      expected_content: "2022/11/17".to_string(),
    },
  ];
  test.run_scripts(scripts).await;
}

// Test when switching the current field from Number to Text test
// input:
//      $1 -> "$1"(This string will be different base on current data setting)
#[tokio::test]
async fn grid_switch_from_number_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::Number).await.clone();

  let scripts = vec![
    SwitchToField {
      field_id: field.id.clone(),
      new_field_type: FieldType::RichText,
    },
    AssertCellContent {
      field_id: field.id.clone(),
      row_index: 0,
      expected_content: "$1".to_string(),
    },
    AssertCellContent {
      field_id: field.id.clone(),
      row_index: 4,
      expected_content: "".to_string(),
    },
  ];

  test.run_scripts(scripts).await;
}

/// Test when switching the current field from Checklist to Text test
#[tokio::test]
async fn grid_switch_from_checklist_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::Checklist).await;

  let scripts = vec![
    SwitchToField {
      field_id: field_rev.id.clone(),
      new_field_type: FieldType::RichText,
    },
    AssertCellContent {
      field_id: field_rev.id.clone(),
      row_index: 0,
      expected_content: "First thing".to_string(),
    },
  ];
  test.run_scripts(scripts).await;
}
