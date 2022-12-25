use crate::grid::sort_test::script::{GridSortTest, SortScript::*};
use flowy_grid::entities::{DeleteSortParams, FieldType};
use flowy_grid::services::sort::SortType;
use grid_rev_model::SortCondition;

#[tokio::test]
async fn sort_text_by_ascending_test() {
    let mut test = GridSortTest::new().await;
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
async fn sort_text_by_ascending_and_delete_sort_test() {
    let mut test = GridSortTest::new().await;
    let text_field = test.get_first_field_rev(FieldType::RichText).clone();
    let view_id = test.grid_id.clone();
    let scripts = vec![InsertSort {
        field_rev: text_field.clone(),
        condition: SortCondition::Ascending,
    }];
    test.run_scripts(scripts).await;
    let sort_rev = test.current_sort_rev.as_ref().unwrap();
    let scripts = vec![
        DeleteSort {
            params: DeleteSortParams {
                view_id,
                sort_type: SortType::from(&text_field),
                sort_id: sort_rev.id.clone(),
            },
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
    let mut test = GridSortTest::new().await;
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
    let mut test = GridSortTest::new().await;
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
    let mut test = GridSortTest::new().await;
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

#[tokio::test]
async fn sort_date_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let date_field = test.get_first_field_rev(FieldType::DateTime);
    let scripts = vec![
        AssertCellContentOrder {
            field_id: date_field.id.clone(),
            orders: vec!["2022/03/14", "2022/03/14", "2022/03/14", "2022/11/17", "2022/11/13"],
        },
        InsertSort {
            field_rev: date_field.clone(),
            condition: SortCondition::Ascending,
        },
        AssertCellContentOrder {
            field_id: date_field.id.clone(),
            orders: vec!["2022/03/14", "2022/03/14", "2022/03/14", "2022/11/13", "2022/11/17"],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_date_by_descending_test() {
    let mut test = GridSortTest::new().await;
    let date_field = test.get_first_field_rev(FieldType::DateTime);
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
            field_rev: date_field.clone(),
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
    let mut test = GridSortTest::new().await;
    let number_field = test.get_first_field_rev(FieldType::Number);
    let scripts = vec![
        AssertCellContentOrder {
            field_id: number_field.id.clone(),
            orders: vec!["$1", "$2", "$3", "$4", "", "$5"],
        },
        InsertSort {
            field_rev: number_field.clone(),
            condition: SortCondition::Descending,
        },
        AssertCellContentOrder {
            field_id: number_field.id.clone(),
            orders: vec!["$5", "$4", "$3", "$2", "$1", ""],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_single_select_by_descending_test() {
    let mut test = GridSortTest::new().await;
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
    let mut test = GridSortTest::new().await;
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
