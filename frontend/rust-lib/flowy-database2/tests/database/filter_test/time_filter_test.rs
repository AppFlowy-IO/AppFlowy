use flowy_database2::entities::{FieldType, NumberFilterConditionPB, TimeFilterPB};
use lib_infra::box_any::BoxAny;

use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged};

#[tokio::test]
async fn grid_filter_time_is_equal_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 1;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Time,
      data: BoxAny::new(TimeFilterPB {
        condition: NumberFilterConditionPB::Equal,
        content: "75".to_string(),
      }),
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
async fn grid_filter_time_is_less_than_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 1;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Time,

      data: BoxAny::new(TimeFilterPB {
        condition: NumberFilterConditionPB::LessThan,
        content: "80".to_string(),
      }),
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
async fn grid_filter_time_is_less_than_or_equal_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 1;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Time,
      data: BoxAny::new(TimeFilterPB {
        condition: NumberFilterConditionPB::LessThanOrEqualTo,
        content: "75".to_string(),
      }),
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
async fn grid_filter_time_is_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 6;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Time,
      data: BoxAny::new(TimeFilterPB {
        condition: NumberFilterConditionPB::NumberIsEmpty,
        content: "".to_string(),
      }),
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
async fn grid_filter_time_is_not_empty_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 1;
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Time,
      data: BoxAny::new(TimeFilterPB {
        condition: NumberFilterConditionPB::NumberIsNotEmpty,
        content: "".to_string(),
      }),
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected },
  ];
  test.run_scripts(scripts).await;
}
