use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::{FilterRowChanged, GridFilterTest};
use flowy_grid::entities::ChecklistFilterConditionPB;

#[tokio::test]
async fn grid_filter_checklist_is_incomplete_test() {
    let mut test = GridFilterTest::new().await;
    let expected = 5;
    let row_count = test.row_revs.len();
    let scripts = vec![
        CreateChecklistFilter {
            condition: ChecklistFilterConditionPB::IsIncomplete,
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
async fn grid_filter_checklist_is_complete_test() {
    let mut test = GridFilterTest::new().await;
    let expected = 1;
    let row_count = test.row_revs.len();
    let scripts = vec![
        CreateChecklistFilter {
            condition: ChecklistFilterConditionPB::IsComplete,
            changed: Some(FilterRowChanged {
                showing_num_of_rows: 0,
                hiding_num_of_rows: row_count - expected,
            }),
        },
        AssertNumberOfVisibleRows { expected },
    ];
    test.run_scripts(scripts).await;
}
