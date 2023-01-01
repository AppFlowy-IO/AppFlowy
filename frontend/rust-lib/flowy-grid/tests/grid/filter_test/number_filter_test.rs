use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::{FilterRowChanged, GridFilterTest};
use flowy_grid::entities::NumberFilterConditionPB;

#[tokio::test]
async fn grid_filter_number_is_equal_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 1;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::Equal,
            content: "1".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_less_than_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 2;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::LessThan,
            content: "3".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
#[should_panic]
async fn grid_filter_number_is_less_than_test2() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 2;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::LessThan,
            content: "$3".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_less_than_or_equal_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 3;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::LessThanOrEqualTo,
            content: "3".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_empty_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 1;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::NumberIsEmpty,
            content: "".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_number_is_not_empty_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    let expected = 5;
    let scripts = vec![
        CreateNumberFilter {
            condition: NumberFilterConditionPB::NumberIsNotEmpty,
            content: "".to_string(),
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}
