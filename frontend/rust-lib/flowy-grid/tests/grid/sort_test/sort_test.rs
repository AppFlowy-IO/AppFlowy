use crate::grid::sort_test::script::{GridSortTest, SortScript::*};
use flowy_grid::entities::{AlterSortParams, DeleteSortParams, FieldType};
use flowy_grid::services::sort::SortType;
use grid_rev_model::SortCondition;

#[tokio::test]
async fn sort_text_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let text_field = test.get_first_field_rev(FieldType::RichText);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: text_field.id.clone(),
            orders: vec!["A", "", "C", "DA", "AE"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: text_field.id.clone(),
                sort_id: None,
                field_type: FieldType::RichText.into(),
                condition: SortCondition::Ascending.into(),
            },
        },
        AssertTextOrder {
            field_id: text_field.id.clone(),
            orders: vec!["", "A", "AE", "C", "DA"],
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
        params: AlterSortParams {
            view_id: view_id.clone(),
            field_id: text_field.id.clone(),
            sort_id: None,
            field_type: FieldType::RichText.into(),
            condition: SortCondition::Ascending.into(),
        },
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
        AssertTextOrder {
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
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: text_field.id.clone(),
            orders: vec!["A", "", "C", "DA", "AE"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: text_field.id.clone(),
                sort_id: None,
                field_type: FieldType::RichText.into(),
                condition: SortCondition::Descending.into(),
            },
        },
        AssertTextOrder {
            field_id: text_field.id.clone(),
            orders: vec!["DA", "C", "AE", "A", ""],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_checkbox_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let checkbox_field = test.get_first_field_rev(FieldType::Checkbox);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: checkbox_field.id.clone(),
            orders: vec!["Yes", "Yes", "No", "No", "No"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: checkbox_field.id.clone(),
                sort_id: None,
                field_type: FieldType::Checkbox.into(),
                condition: SortCondition::Ascending.into(),
            },
        },
        // AssertTextOrder {
        //     field_id: checkbox_field.id.clone(),
        //     orders: vec!["No", "No", "No", "Yes", "Yes"],
        // },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_checkbox_by_descending_test() {
    let mut test = GridSortTest::new().await;
    let checkbox_field = test.get_first_field_rev(FieldType::Checkbox);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: checkbox_field.id.clone(),
            orders: vec!["Yes", "Yes", "No", "No", "No"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: checkbox_field.id.clone(),
                sort_id: None,
                field_type: FieldType::Checkbox.into(),
                condition: SortCondition::Descending.into(),
            },
        },
        AssertTextOrder {
            field_id: checkbox_field.id.clone(),
            orders: vec!["Yes", "Yes", "No", "No", "No"],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_date_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let date_field = test.get_first_field_rev(FieldType::DateTime);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: date_field.id.clone(),
            orders: vec!["2022/03/14", "2022/03/14", "2022/03/14", "2022/11/17", "2022/11/13"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: date_field.id.clone(),
                sort_id: None,
                field_type: FieldType::DateTime.into(),
                condition: SortCondition::Ascending.into(),
            },
        },
        AssertTextOrder {
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
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: date_field.id.clone(),
            orders: vec!["2022/03/14", "2022/03/14", "2022/03/14", "2022/11/17", "2022/11/13"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: date_field.id.clone(),
                sort_id: None,
                field_type: FieldType::DateTime.into(),
                condition: SortCondition::Descending.into(),
            },
        },
        AssertTextOrder {
            field_id: date_field.id.clone(),
            orders: vec!["2022/11/17", "2022/11/13", "2022/03/14", "2022/03/14", "2022/03/14"],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_number_by_descending_test() {
    let mut test = GridSortTest::new().await;
    let number_field = test.get_first_field_rev(FieldType::Number);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: number_field.id.clone(),
            orders: vec!["$1", "$2", "$3", "$4", ""],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: number_field.id.clone(),
                sort_id: None,
                field_type: FieldType::Number.into(),
                condition: SortCondition::Descending.into(),
            },
        },
        AssertTextOrder {
            field_id: number_field.id.clone(),
            orders: vec!["$4", "$3", "$2", "$1", ""],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_single_select_by_descending_test() {
    let mut test = GridSortTest::new().await;
    let single_select = test.get_first_field_rev(FieldType::SingleSelect);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: single_select.id.clone(),
            orders: vec!["", "", "Completed", "Completed", "Planned"],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: single_select.id.clone(),
                sort_id: None,
                field_type: FieldType::SingleSelect.into(),
                condition: SortCondition::Descending.into(),
            },
        },
        AssertTextOrder {
            field_id: single_select.id.clone(),
            orders: vec!["Planned", "Completed", "Completed", "", ""],
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn sort_multi_select_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let multi_select = test.get_first_field_rev(FieldType::MultiSelect);
    let view_id = test.grid_id.clone();
    let scripts = vec![
        AssertTextOrder {
            field_id: multi_select.id.clone(),
            orders: vec!["Google,Facebook", "Google,Twitter", "Facebook", "", ""],
        },
        InsertSort {
            params: AlterSortParams {
                view_id,
                field_id: multi_select.id.clone(),
                sort_id: None,
                field_type: FieldType::MultiSelect.into(),
                condition: SortCondition::Ascending.into(),
            },
        },
        AssertTextOrder {
            field_id: multi_select.id.clone(),
            orders: vec!["", "", "Facebook", "Google,Facebook", "Google,Twitter"],
        },
    ];
    test.run_scripts(scripts).await;
}
