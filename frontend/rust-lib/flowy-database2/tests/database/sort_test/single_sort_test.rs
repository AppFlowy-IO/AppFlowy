use crate::database::sort_test::script::DatabaseSortTest;
use flowy_database2::entities::{CheckboxFilterConditionPB, CheckboxFilterPB, FieldType};
use flowy_database2::services::sort::SortCondition;
use lib_infra::box_any::BoxAny;

#[tokio::test]
async fn sort_text_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;
  test
    .insert_sort(text_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "AE", "C", "CB", "DA", ""],
    )
    .await;

  let checkbox_filter = CheckboxFilterPB {
    condition: CheckboxFilterConditionPB::IsChecked,
  };
  test
    .insert_filter(FieldType::Checkbox, BoxAny::new(checkbox_filter))
    .await;

  test
    .assert_cell_content_order(text_field.id.clone(), vec!["A", "AE", ""])
    .await;
}

#[tokio::test]
async fn sort_text_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;
  test
    .insert_sort(text_field.clone(), SortCondition::Descending)
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["DA", "CB", "C", "AE", "AE", "A", ""],
    )
    .await;
}

#[tokio::test]
async fn sort_change_notification_by_update_text_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;
  test
    .insert_sort(text_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "AE", "C", "CB", "DA", ""],
    )
    .await;
  test.wait(200).await;

  let row = test.get_rows().await;
  test
    .update_text_cell(row[1].id.clone(), "E".to_string())
    .await;
  test
    .assert_sort_changed(
      vec!["A", "E", "AE", "C", "CB", "DA", ""],
      vec!["A", "AE", "C", "CB", "DA", "E", ""],
    )
    .await;
}

#[tokio::test]
async fn sort_after_new_row_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;

  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "No", "Yes", ""],
    )
    .await;
  test
    .insert_sort(checkbox_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["No", "No", "No", "", "Yes", "Yes", "Yes"],
    )
    .await;

  test.add_new_row().await;
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["No", "No", "No", "", "", "Yes", "Yes", "Yes"],
    )
    .await;
}

#[tokio::test]
async fn sort_text_by_ascending_and_delete_sort_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).await;

  test
    .insert_sort(text_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "AE", "AE", "C", "CB", "DA", ""],
    )
    .await;

  let sort = test.editor.get_all_sorts(&test.view_id).await.items[0].clone();
  test.delete_sort(sort.id.clone()).await;
  test
    .assert_cell_content_order(
      text_field.id.clone(),
      vec!["A", "", "C", "DA", "AE", "AE", "CB"],
    )
    .await;
}

#[tokio::test]
async fn sort_checkbox_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;

  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "No", "Yes", ""],
    )
    .await;
  test
    .insert_sort(checkbox_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["No", "No", "No", "", "Yes", "Yes", "Yes"],
    )
    .await;
}

#[tokio::test]
async fn sort_checkbox_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox).await;

  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "No", "No", "No", "Yes", ""],
    )
    .await;
  test
    .insert_sort(checkbox_field.clone(), SortCondition::Descending)
    .await;
  test
    .assert_cell_content_order(
      checkbox_field.id.clone(),
      vec!["Yes", "Yes", "Yes", "No", "No", "No", ""],
    )
    .await;
}

#[tokio::test]
async fn sort_date_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime).await;

  test
    .assert_cell_content_order(
      date_field.id.clone(),
      vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/17",
        "2022/11/13",
        "2022/12/25",
        "",
      ],
    )
    .await;
  test
    .insert_sort(date_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      date_field.id.clone(),
      vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/13",
        "2022/11/17",
        "2022/12/25",
        "",
      ],
    )
    .await;
}

#[tokio::test]
async fn sort_date_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime).await;

  test
    .assert_cell_content_order(
      date_field.id.clone(),
      vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/17",
        "2022/11/13",
        "2022/12/25",
        "",
      ],
    )
    .await;
  test
    .insert_sort(date_field.clone(), SortCondition::Descending)
    .await;
  test
    .assert_cell_content_order(
      date_field.id.clone(),
      vec![
        "2022/12/25",
        "2022/11/17",
        "2022/11/13",
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "",
      ],
    )
    .await;
}

#[tokio::test]
async fn sort_number_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let number_field = test.get_first_field(FieldType::Number).await;

  test
    .assert_cell_content_order(
      number_field.id.clone(),
      vec!["$1", "$2", "$3", "$14", "", "$5", ""],
    )
    .await;
  test
    .insert_sort(number_field.clone(), SortCondition::Ascending)
    .await;
  test
    .assert_cell_content_order(
      number_field.id.clone(),
      vec!["$1", "$2", "$3", "$5", "$14", "", ""],
    )
    .await;
}

#[tokio::test]
async fn sort_number_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let number_field = test.get_first_field(FieldType::Number).await;

  test
    .assert_cell_content_order(
      number_field.id.clone(),
      vec!["$1", "$2", "$3", "$14", "", "$5", ""],
    )
    .await;
  test
    .insert_sort(number_field.clone(), SortCondition::Descending)
    .await;
  test
    .assert_cell_content_order(
      number_field.id.clone(),
      vec!["$14", "$5", "$3", "$2", "$1", "", ""],
    )
    .await;
}
