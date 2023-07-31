use flowy_database2::entities::DateFilterConditionPB;

use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged};

#[tokio::test]
async fn grid_filter_date_is_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 3;
  let scripts = vec![
    CreateDateFilter {
      condition: DateFilterConditionPB::DateIs,
      start: None,
      end: None,
      timestamp: Some(1647251762),
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
async fn grid_filter_date_after_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 3;
  let scripts = vec![
    CreateDateFilter {
      condition: DateFilterConditionPB::DateAfter,
      start: None,
      end: None,
      timestamp: Some(1647251762),
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
async fn grid_filter_date_on_or_after_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 3;
  let scripts = vec![
    CreateDateFilter {
      condition: DateFilterConditionPB::DateOnOrAfter,
      start: None,
      end: None,
      timestamp: Some(1668359085),
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
async fn grid_filter_date_on_or_before_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 4;
  let scripts = vec![
    CreateDateFilter {
      condition: DateFilterConditionPB::DateOnOrBefore,
      start: None,
      end: None,
      timestamp: Some(1668359085),
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
async fn grid_filter_date_within_test() {
  let mut test = DatabaseFilterTest::new().await;
  let row_count = test.row_details.len();
  let expected = 5;
  let scripts = vec![
    CreateDateFilter {
      condition: DateFilterConditionPB::DateWithIn,
      start: Some(1647251762),
      end: Some(1668704685),
      timestamp: None,
      changed: Some(FilterRowChanged {
        showing_num_of_rows: 0,
        hiding_num_of_rows: row_count - expected,
      }),
    },
    AssertNumberOfVisibleRows { expected },
  ];
  test.run_scripts(scripts).await;
}
