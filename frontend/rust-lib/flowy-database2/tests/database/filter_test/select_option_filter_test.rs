use flowy_database2::entities::{FieldType, SelectOptionConditionPB};

use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged};

#[tokio::test]
async fn grid_filter_multi_select_is_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateMultiSelectFilter {
      condition: SelectOptionConditionPB::OptionIsEmpty,
      option_ids: vec![],
    },
    AssertNumberOfVisibleRows { expected: 2 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_multi_select_is_not_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let scripts = vec![
    CreateMultiSelectFilter {
      condition: SelectOptionConditionPB::OptionIsNotEmpty,
      option_ids: vec![],
    },
    AssertNumberOfVisibleRows { expected: 5 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_multi_select_is_test() {
  let mut test = DatabaseFilterTest::new().await;
  let field = test.get_first_field(FieldType::MultiSelect);
  let mut options = test.get_multi_select_type_option(&field.id);
  let scripts = vec![
    CreateMultiSelectFilter {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![options.remove(0).id, options.remove(0).id],
    },
    AssertNumberOfVisibleRows { expected: 5 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_multi_select_is_test2() {
  let mut test = DatabaseFilterTest::new().await;
  let field = test.get_first_field(FieldType::MultiSelect);
  let mut options = test.get_multi_select_type_option(&field.id);
  let scripts = vec![
    CreateMultiSelectFilter {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![options.remove(1).id],
    },
    AssertNumberOfVisibleRows { expected: 4 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_single_select_is_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 3;
  let row_count = test.row_details.len();
  let scripts = vec![
    CreateSingleSelectFilter {
      condition: SelectOptionConditionPB::OptionIsEmpty,
      option_ids: vec![],
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_single_select_is_test() {
  let mut test = DatabaseFilterTest::new().await;
  let field = test.get_first_field(FieldType::SingleSelect);
  let mut options = test.get_single_select_type_option(&field.id).options;
  let expected = 2;
  let row_count = test.row_details.len();
  let scripts = vec![
    CreateSingleSelectFilter {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![options.remove(0).id],
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected: 2 },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_single_select_is_test2() {
  let mut test = DatabaseFilterTest::new().await;
  let field = test.get_first_field(FieldType::SingleSelect);
  let row_details = test.get_rows().await;
  let mut options = test.get_single_select_type_option(&field.id).options;
  let option = options.remove(0);
  let row_count = test.row_details.len();

  let scripts = vec![
    CreateSingleSelectFilter {
      condition: SelectOptionConditionPB::OptionIs,
      option_ids: vec![option.id.clone()],
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - 2,
      }),
    },
    AssertNumberOfVisibleRows { expected: 2 },
    UpdateSingleSelectCell {
      row_id: row_details[1].row.id.clone(),
      option_id: option.id.clone(),
      changed: None,
    },
    AssertNumberOfVisibleRows { expected: 3 },
    UpdateSingleSelectCell {
      row_id: row_details[1].row.id.clone(),
      option_id: "".to_string(),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: 1,
      }),
    },
    AssertNumberOfVisibleRows { expected: 2 },
  ];
  test.run_scripts(scripts).await;
}
