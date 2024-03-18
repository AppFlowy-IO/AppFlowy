use flowy_database2::entities::{CheckboxFilterConditionPB, CheckboxFilterPB, FieldType};
use lib_infra::box_any::BoxAny;

use crate::database::filter_test::script::FilterScript::*;
use crate::database::filter_test::script::{DatabaseFilterTest, FilterRowChanged};

#[tokio::test]
async fn grid_filter_checkbox_is_check_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 3;
  let row_count = test.row_details.len();
  // The initial number of checked is 3
  // The initial number of unchecked is 4
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Checkbox,
      data: BoxAny::new(CheckboxFilterPB {
        condition: CheckboxFilterConditionPB::IsChecked,
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
async fn grid_filter_checkbox_is_uncheck_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 4;
  let row_count = test.row_details.len();
  let scripts = vec![
    CreateDataFilter {
      parent_filter_id: None,
      field_type: FieldType::Checkbox,
      data: BoxAny::new(CheckboxFilterPB {
        condition: CheckboxFilterConditionPB::IsUnChecked,
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
