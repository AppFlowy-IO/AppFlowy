use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::CheckboxFilterCondition;

#[tokio::test]
async fn grid_filter_checkbox_is_check_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateCheckboxFilter {
            condition: CheckboxFilterCondition::IsChecked,
        },
        AssertNumberOfRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_checkbox_is_uncheck_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateCheckboxFilter {
            condition: CheckboxFilterCondition::IsUnChecked,
        },
        AssertNumberOfRows { expected: 3 },
    ];
    test.run_scripts(scripts).await;
}
