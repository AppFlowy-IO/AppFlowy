use flowy_database2::entities::FieldType;
use flowy_database2::services::sort::SortCondition;

use crate::database::sort_test::script::DatabaseSortTest;
use crate::database::sort_test::script::SortScript::*;

#[tokio::test]
async fn sort_text_with_checkbox_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).clone();
  let checkbox_field = test.get_first_field(FieldType::Checkbox).clone();
  let scripts = vec![
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No"],
    },
    InsertSort {
      field: text_field.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["", "A", "AE", "AE", "C", "DA"],
    },
  ];
  test.run_scripts(scripts).await;

  let scripts = vec![
    InsertSort {
      field: checkbox_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["", "A", "AE", "AE", "C", "DA"],
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "Yes", "No", "No"],
    },
  ];
  test.run_scripts(scripts).await;
}
