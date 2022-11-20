use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::DateFilterCondition;

#[tokio::test]
async fn grid_filter_date_is_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateIs,
            start: None,
            end: None,
            timestamp: Some(1647251762),
        },
        AssertNumberOfVisibleRows { expected: 3 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_date_after_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateAfter,
            start: None,
            end: None,
            timestamp: Some(1647251762),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_date_on_or_after_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateOnOrAfter,
            start: None,
            end: None,
            timestamp: Some(1668359085),
        },
        AssertNumberOfVisibleRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_date_on_or_before_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateOnOrBefore,
            start: None,
            end: None,
            timestamp: Some(1668359085),
        },
        AssertNumberOfVisibleRows { expected: 4 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_date_within_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateWithIn,
            start: Some(1647251762),
            end: Some(1668704685),
            timestamp: None,
        },
        AssertNumberOfVisibleRows { expected: 5 },
    ];
    test.run_scripts(scripts).await;
}
