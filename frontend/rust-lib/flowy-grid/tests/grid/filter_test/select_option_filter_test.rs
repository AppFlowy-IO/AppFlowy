use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::{NumberFilterCondition, SelectOptionCondition};

#[tokio::test]
async fn grid_filter_multi_select_is_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateMultiSelectFilter {
            condition: SelectOptionCondition::OptionIsEmpty,
            option_ids: vec![],
        },
        AssertNumberOfRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_multi_select_is_not_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateMultiSelectFilter {
            condition: SelectOptionCondition::OptionIsNotEmpty,
            option_ids: vec![],
        },
        AssertNumberOfRows { expected: 3 },
    ];
    test.run_scripts(scripts).await;
}
