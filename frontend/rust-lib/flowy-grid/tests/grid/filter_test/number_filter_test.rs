use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::NumberFilterCondition;

#[tokio::test]
async fn grid_filter_number_is_equal_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::Equal,
            content: "1".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 1 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_less_than_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::LessThan,
            content: "3".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
#[should_panic]
async fn grid_filter_number_is_less_than_test2() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::LessThan,
            content: "$3".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_less_than_or_equal_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::LessThanOrEqualTo,
            content: "3".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 3 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::NumberIsEmpty,
            content: "".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 1 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_not_empty_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterCondition::NumberIsNotEmpty,
            content: "".to_string(),
        },
        AssertNumberOfVisibleRows { expected: 4 },
    ];
    test.run_scripts(scripts).await;
}
