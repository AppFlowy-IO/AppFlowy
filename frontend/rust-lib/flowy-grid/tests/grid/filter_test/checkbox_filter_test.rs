use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::{FilterRowChanged, GridFilterTest};
use flowy_grid::entities::CheckboxFilterConditionPB;

#[tokio::test]
async fn grid_filter_checkbox_is_check_test() {
    let mut test = GridFilterTest::new().await;
    let row_count = test.row_revs.len();
    // The initial number of unchecked is 3
    // The initial number of checked is 2
    let scripts = vec![CreateCheckboxFilter {
        condition: CheckboxFilterConditionPB::IsChecked,
        changed: Some(FilterRowChanged {
            showing_num_of_rows: 0,
            hiding_num_of_rows: row_count - 3,
        }),
    }];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_checkbox_is_uncheck_test() {
    let mut test = GridFilterTest::new().await;
    let expected = 3;
    let row_count = test.row_revs.len();
    let scripts = vec![
        CreateCheckboxFilter {
            condition: CheckboxFilterConditionPB::IsUnChecked,
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}
