use crate::database::sort_test::script::{DatabaseSortTest, SortScript::*};
use database_model::SortCondition;
use flowy_database::entities::FieldType;

#[tokio::test]
async fn sort_text_by_ascending_test() {
  let mut test = DatabaseSortTest::new().await;
  let text_field = test.get_first_field_rev(FieldType::RichText);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
    },
    InsertSort {
      field_rev: text_field.clone(),
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
  let text_field = test.get_first_field_rev(FieldType::RichText).clone();
  let scripts = vec![
    InsertSort {
      field_rev: text_field.clone(),
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

  let row_revs = test.get_row_revs().await;
  let scripts = vec![
    UpdateTextCell {
      row_id: row_revs[2].id.clone(),
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
  let text_field = test.get_first_field_rev(FieldType::RichText).clone();
  let scripts = vec![InsertSort {
    field_rev: text_field.clone(),
    condition: SortCondition::Ascending,
  }];
  test.run_scripts(scripts).await;
  let sort_rev = test.current_sort_rev.as_ref().unwrap();
  let scripts = vec![
    DeleteSort {
      field_rev: text_field.clone(),
      sort_id: sort_rev.id.clone(),
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
  let text_field = test.get_first_field_rev(FieldType::RichText);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: text_field.id.clone(),
      orders: vec!["A", "", "C", "DA", "AE", "AE"],
    },
    InsertSort {
      field_rev: text_field.clone(),
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
  let checkbox_field = test.get_first_field_rev(FieldType::Checkbox);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No"],
    },
    InsertSort {
      field_rev: checkbox_field.clone(),
      condition: SortCondition::Ascending,
    },
  ];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_checkbox_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let checkbox_field = test.get_first_field_rev(FieldType::Checkbox);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "No", "No", "No", "Yes"],
    },
    InsertSort {
      field_rev: checkbox_field.clone(),
      condition: SortCondition::Descending,
    },
    AssertCellContentOrder {
      field_id: checkbox_field.id.clone(),
      orders: vec!["Yes", "Yes", "Yes", "No", "No", "No"],
    },
  ];
  test.run_scripts(scripts).await;
}

// #[tokio::test]
// async fn sort_date_by_ascending_test() {
//   let mut test = DatabaseSortTest::new().await;
//   let date_field = test.get_first_field_rev(FieldType::DateTime);
//   let scripts = vec![
//     AssertCellContentOrder {
//       field_id: date_field.id.clone(),
//       orders: vec![
//         "2022/03/14",
//         "2022/03/14",
//         "2022/03/14",
//         "2022/11/17",
//         "2022/11/13",
//       ],
//     },
//     InsertSort {
//       field_rev: date_field.clone(),
//       condition: SortCondition::Ascending,
//     },
//     AssertCellContentOrder {
//       field_id: date_field.id.clone(),
//       orders: vec![
//         "2022/03/14",
//         "2022/03/14",
//         "2022/03/14",
//         "2022/11/13",
//         "2022/11/17",
//       ],
//     },
//   ];
//   test.run_scripts(scripts).await;
// }

// #[tokio::test]
// async fn sort_date_by_descending_test() {
//   let mut test = DatabaseSortTest::new().await;
//   let date_field = test.get_first_field_rev(FieldType::DateTime);
//   let scripts = vec![
//     AssertCellContentOrder {
//       field_id: date_field.id.clone(),
//       orders: vec![
//         "2022/03/14",
//         "2022/03/14",
//         "2022/03/14",
//         "2022/11/17",
//         "2022/11/13",
//         "2022/12/25",
//       ],
//     },
//     InsertSort {
//       field_rev: date_field.clone(),
//       condition: SortCondition::Descending,
//     },
//     AssertCellContentOrder {
//       field_id: date_field.id.clone(),
//       orders: vec![
//         "2022/12/25",
//         "2022/11/17",
//         "2022/11/13",
//         "2022/03/14",
//         "2022/03/14",
//         "2022/03/14",
//       ],
//     },
//   ];
//   test.run_scripts(scripts).await;
// }

#[tokio::test]
async fn sort_number_by_descending_test() {
  let mut test = DatabaseSortTest::new().await;
  let number_field = test.get_first_field_rev(FieldType::Number);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: number_field.id.clone(),
      orders: vec!["$1", "$2", "$3", "$14", "", "$5"],
    },
    InsertSort {
      field_rev: number_field.clone(),
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
  let single_select = test.get_first_field_rev(FieldType::SingleSelect);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: single_select.id.clone(),
      orders: vec!["", "", "Completed", "Completed", "Planned", "Planned"],
    },
    InsertSort {
      field_rev: single_select.clone(),
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
  let multi_select = test.get_first_field_rev(FieldType::MultiSelect);
  let scripts = vec![
    AssertCellContentOrder {
      field_id: multi_select.id.clone(),
      orders: vec!["Google,Facebook", "Google,Twitter", "Facebook", "", "", ""],
    },
    InsertSort {
      field_rev: multi_select.clone(),
      condition: SortCondition::Ascending,
    },
    AssertCellContentOrder {
      field_id: multi_select.id.clone(),
      orders: vec!["", "", "", "Facebook", "Google,Facebook", "Google,Twitter"],
    },
  ];
  test.run_scripts(scripts).await;
}
