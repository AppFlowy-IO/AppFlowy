use flowy_database2::entities::FieldType;
use flowy_database2::services::sort::SortCondition;

use crate::database::sort_test::script::DatabaseSortTest;

#[tokio::test]
async fn sort_checkbox_and_then_text_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  // Assert initial cell content order for checkbox and text fields
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "No", "Yes", ""],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;

  // Insert checkbox sort (Descending)
  test
    .insert_sort(checkbox_field.clone(), SortCondition::Descending)
    .await;

  // Assert sorted order for checkbox and text fields
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "Yes", "No", "No", "No", ""],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "AE", "C", "DA", "AE", "CB"],
    )
    .await;

  // Insert text sort (Ascending)
  test
    .insert_sort(text_field.clone(), SortCondition::Ascending)
    .await;

  // Assert sorted order after adding text sort
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "Yes", "No", "No", "", "No"],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "", "AE", "C", "CB", "DA"],
    )
    .await;
}

#[tokio::test]
async fn reorder_sort_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  // Assert initial cell content order for checkbox and text fields
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "No", "Yes", ""],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;

  // Insert checkbox and text sorts
  test
    .insert_sort(checkbox_field.clone(), SortCondition::Descending)
    .await;
  test
    .insert_sort(text_field.clone(), SortCondition::Ascending)
    .await;

  // Assert sorted order after applying both sorts
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "Yes", "No", "No", "", "No"],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "", "AE", "C", "CB", "DA"],
    )
    .await;

  // Reorder sorts
  let sorts = test.editor.get_all_sorts(&test.view_id).await.items;
  test
    .reorder_sort(sorts[1].id.clone(), sorts[0].id.clone())
    .await;

  // Assert the order after reorder
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "", "No", "Yes"],
    )
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "AE", "C", "CB", "DA", ""],
    )
    .await;
}
