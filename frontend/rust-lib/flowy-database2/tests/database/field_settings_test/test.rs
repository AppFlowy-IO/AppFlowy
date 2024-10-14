use crate::database::field_settings_test::script::DatabaseFieldTest;
use crate::database::field_test::util::*;
use collab_database::database::gen_option_id;
use collab_database::fields::select_type_option::SingleSelectTypeOption;
use collab_database::fields::select_type_option::{SelectOption, SelectTypeOption};
use flowy_database2::entities::{FieldChangesetPB, FieldType};
use flowy_database2::services::field::{CHECK, UNCHECK};

#[tokio::test]
async fn grid_create_field() {
  let mut test = DatabaseFieldTest::new().await;

  // Create and assert a text field
  let (params, field) = create_text_field(&test.view_id());
  test.create_field(params).await;
  test
    .assert_field_type_option_equal(
      test.field_count(),
      field.get_any_type_option(field.field_type).unwrap(),
    )
    .await;

  // Create and assert a single select field
  let (params, field) = create_single_select_field(&test.view_id());
  test.create_field(params).await;
  test
    .assert_field_type_option_equal(
      test.field_count(),
      field.get_any_type_option(field.field_type).unwrap(),
    )
    .await;

  // Create and assert a timestamp field
  let (params, field) = create_timestamp_field(&test.view_id(), FieldType::CreatedTime);
  test.create_field(params).await;
  test
    .assert_field_type_option_equal(
      test.field_count(),
      field.get_any_type_option(field.field_type).unwrap(),
    )
    .await;

  // Create and assert a time field
  let (params, field) = create_time_field(&test.view_id());
  test.create_field(params).await;
  test
    .assert_field_type_option_equal(
      test.field_count(),
      field.get_any_type_option(field.field_type).unwrap(),
    )
    .await;
}

#[tokio::test]
async fn grid_create_duplicate_field() {
  let mut test = DatabaseFieldTest::new().await;
  let (params, _) = create_text_field(&test.view_id());
  let field_count = test.field_count();
  let expected_field_count = field_count + 1;

  test.create_field(params.clone()).await;
  test.assert_field_count(expected_field_count).await;
}

#[tokio::test]
async fn grid_update_field_with_empty_change() {
  let mut test = DatabaseFieldTest::new().await;
  let (params, _) = create_single_select_field(&test.view_id());
  let create_field_index = test.field_count();
  test.create_field(params).await;

  let field = test.get_fields().await.pop().unwrap().clone();
  let changeset = FieldChangesetPB {
    field_id: field.id.clone(),
    view_id: test.view_id(),
    ..Default::default()
  };

  test.update_field(changeset).await;
  test
    .assert_field_type_option_equal(
      create_field_index,
      field.get_any_type_option(field.field_type).unwrap(),
    )
    .await;
}

#[tokio::test]
async fn grid_delete_field() {
  let mut test = DatabaseFieldTest::new().await;
  let original_field_count = test.field_count();
  let (params, _) = create_text_field(&test.view_id());
  test.create_field(params).await;

  let field = test.get_fields().await.pop().unwrap();
  test.delete_field(field).await;
  test.assert_field_count(original_field_count).await;
}

#[tokio::test]
async fn grid_switch_from_select_option_to_checkbox_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::SingleSelect).await;
  let view_id = test.view_id();

  // Update the type option data of the single select option
  let mut options = test.get_single_select_type_option(&field.id).await;
  options.clear();
  options.push(SelectOption {
    id: gen_option_id(),
    name: CHECK.to_string(),
    color: Default::default(),
  });
  options.push(SelectOption {
    id: gen_option_id(),
    name: UNCHECK.to_string(),
    color: Default::default(),
  });

  test
    .update_type_option(
      field.id.clone(),
      SingleSelectTypeOption(SelectTypeOption {
        options,
        disable_color: false,
      })
      .into(),
    )
    .await;

  // Switch to checkbox field
  test
    .switch_to_field(view_id, field.id.clone(), FieldType::Checkbox)
    .await;
}

#[tokio::test]
async fn grid_switch_from_checkbox_to_select_option_test() {
  let mut test = DatabaseFieldTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await.clone();

  // Switch to single-select field
  test
    .switch_to_field(
      test.view_id(),
      checkbox_field.id.clone(),
      FieldType::SingleSelect,
    )
    .await;

  // Assert cell content after switching the field type
  test
    .assert_cell_content(
      checkbox_field.id.clone(),
      1,                 // row_index
      CHECK.to_string(), // expected content
    )
    .await;

  // Check that the options contain both "CHECK" and "UNCHECK"
  let options = test.get_single_select_type_option(&checkbox_field.id).await;
  assert_eq!(options.len(), 2);
  assert!(options.iter().any(|option| option.name == UNCHECK));
  assert!(options.iter().any(|option| option.name == CHECK));
}

#[tokio::test]
async fn grid_switch_from_multi_select_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::MultiSelect).await.clone();
  let multi_select_type_option = test.get_multi_select_type_option(&field_rev.id).await;

  test
    .switch_to_field(test.view_id(), field_rev.id.clone(), FieldType::RichText)
    .await;

  test
    .assert_cell_content(
      field_rev.id.clone(),
      0, // row_index
      format!(
        "{},{}",
        multi_select_type_option.first().unwrap().name,
        multi_select_type_option.get(1).unwrap().name
      ),
    )
    .await;
}

#[tokio::test]
async fn grid_switch_from_checkbox_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::Checkbox).await;

  test
    .switch_to_field(test.view_id(), field_rev.id.clone(), FieldType::RichText)
    .await;

  test
    .assert_cell_content(field_rev.id.clone(), 1, "Yes".to_string())
    .await;
  test
    .assert_cell_content(field_rev.id.clone(), 2, "No".to_string())
    .await;
}

#[tokio::test]
async fn grid_switch_from_date_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::DateTime).await.clone();

  test
    .switch_to_field(test.view_id(), field.id.clone(), FieldType::RichText)
    .await;

  test
    .assert_cell_content(field.id.clone(), 2, "2022/03/14".to_string())
    .await;
  test
    .assert_cell_content(field.id.clone(), 3, "2022/11/17".to_string())
    .await;
}

#[tokio::test]
async fn grid_switch_from_number_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field = test.get_first_field(FieldType::Number).await.clone();

  test
    .switch_to_field(test.view_id(), field.id.clone(), FieldType::RichText)
    .await;

  test
    .assert_cell_content(field.id.clone(), 0, "$1".to_string())
    .await;
  test
    .assert_cell_content(field.id.clone(), 4, "".to_string())
    .await;
}

#[tokio::test]
async fn grid_switch_from_checklist_to_text_test() {
  let mut test = DatabaseFieldTest::new().await;
  let field_rev = test.get_first_field(FieldType::Checklist).await;

  test
    .switch_to_field(test.view_id(), field_rev.id.clone(), FieldType::RichText)
    .await;

  test
    .assert_cell_content(field_rev.id.clone(), 0, "First thing".to_string())
    .await;
}
