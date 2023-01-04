use crate::grid::sort_test::script::GridSortTest;
use crate::grid::sort_test::script::SortScript::*;
use flowy_grid::entities::FieldType;
use grid_rev_model::SortCondition;

#[tokio::test]
async fn sort_text_with_checkbox_by_ascending_test() {
    let mut test = GridSortTest::new().await;
    let text_field = test.get_first_field_rev(FieldType::RichText).clone();
    let checkbox_field = test.get_first_field_rev(FieldType::Checkbox).clone();
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
            field_rev: text_field.clone(),
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
            field_rev: checkbox_field.clone(),
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
