use flowy_database2::entities::FieldType;
use flowy_database2::services::sort::SortCondition;

use crate::database::sort_test::script::DatabaseSortTest;
use crate::database::sort_test::script::SortScript::{AssertCellContentOrder, InsertSort};

#[tokio::test]
async fn sort_checkbox_and_then_text_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox);
  let text_field = test.get_first_field(FieldType::RichText);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No", "Yes"],
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
    },
    // // Insert checkbox sort
    InsertSort {
      field: checkbox_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "Yes", "No", "No", "No"],
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "AE", "C", "DA", "AE"],
    },
    // Insert text sort. After inserting the text sort, the order of the rows
    // will be changed.
    // before: ["A", "", "AE", "C", "DA", "AE"]
    // after: ["", "A", "AE", "AE", "C", "DA"]
    InsertSort {
      field: text_field.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "Yes", "No", "No", "No"],
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["", "A", "AE", "AE", "C", "DA"],
    },
  ];
  test.run_scripts(scripts).await;
}
