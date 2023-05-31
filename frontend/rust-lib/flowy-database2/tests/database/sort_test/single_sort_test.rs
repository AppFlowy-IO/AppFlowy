use flowy_database2::entities::FieldType;
use flowy_database2::services::sort::SortCondition;

use crate::database::sort_test::script::{DatabaseSortTest, SortScript::*};

#[tokio::test]
async fn sort_text_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
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
}

#[tokio::test]
async fn sort_change_notification_by_update_text_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).clone();
  let scripts = vec![
    InsertSort {
      field: text_field.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["", "A", "AE", "AE", "C", "DA"],
    },
    // Wait the insert task to finish. The cost of time should be less than 200 milliseconds.
    Wait { millis: 200 },
  ];
  test.run_scripts(scripts).await;

  let rows = test.get_rows().await;
  let scripts = vec![
    UpdateTextCell {
      row_id: rows[2].id.clone(),
      text: "E".to_string(),
    },
    AssertSortChanged {
      old_row_orders: vec!["", "A", "E", "AE", "C", "DA"],
      new_row_orders: vec!["", "A", "AE", "C", "DA", "E"],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_text_by_ascending_and_delete_sort_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText).clone();
  let scripts = vec![InsertSort {
    field: text_field.clone(),
    condition: SortCondition::Ascending,
  }];
  test.run_scripts(scripts).await;
  let sort = test.current_sort_rev.as_ref().unwrap();
  let scripts = vec![
    DeleteSort {
      sort: sort.clone(),
      sort_id: sort.id.clone(),
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE"],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_text_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
    },
    InsertSort {
      field: text_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["DA", "C", "AE", "AE", "A", ""],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_checkbox_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No"],
    },
    InsertSort {
      field: checkbox_field.clone(),
      condition: SortCondition::Ascending,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_checkbox_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No", "Yes"],
    },
    InsertSort {
      field: checkbox_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "Yes", "No", "No", "No"],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_date_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: date_field.id.clone(),
      orders: vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/17",
        "2022/11/13",
      ],
    },
    InsertSort {
      field: date_field.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: date_field.id.clone(),
      orders: vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/13",
        "2022/11/17",
      ],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_date_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let date_field = test.get_first_field(FieldType::DateTime);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: date_field.id.clone(),
      orders: vec![
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
        "2022/11/17",
        "2022/11/13",
        "2022/12/25",
      ],
    },
    InsertSort {
      field: date_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: date_field.id.clone(),
      orders: vec![
        "2022/12/25",
        "2022/11/17",
        "2022/11/13",
        "2022/03/14",
        "2022/03/14",
        "2022/03/14",
      ],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_number_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let number_field = test.get_first_field(FieldType::Number);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: number_field.id.clone(),
      orders: vec!["$1", "$2", "$3", "$14", "", "$5"],
    },
    InsertSort {
      field: number_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: number_field.id.clone(),
      orders: vec!["$14", "$5", "$3", "$2", "$1", ""],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_single_select_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let single_select = test.get_first_field(FieldType::SingleSelect);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: single_select.id.clone(),
      orders: vec!["", "", "Completed", "Completed", "Planned", "Planned"],
    },
    InsertSort {
      field: single_select.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: single_select.id.clone(),
      orders: vec!["Planned", "Planned", "Completed", "Completed", "", ""],
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_multi_select_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let multi_select = test.get_first_field(FieldType::MultiSelect);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: multi_select.id.clone(),
      orders: vec!["Google,Facebook", "Google,Twitter", "Facebook", "", "", ""],
    },
    InsertSort {
      field: multi_select.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: multi_select.id.clone(),
      orders: vec!["", "", "", "Facebook", "Google,Facebook", "Google,Twitter"],
    },
  ];
  test.run_scripts(scripts).await;
}
