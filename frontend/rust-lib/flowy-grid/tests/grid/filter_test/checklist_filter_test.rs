use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::ChecklistFilterConditionPB;

#[tokio::test]
async fn grid_filter_checklist_is_incomplete_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateChecklistFilter {
            condition: ChecklistFilterConditionPB::IsIncomplete,
        },
        AssertNumberOfVisibleRows { expected: 4 },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_filter_checklist_is_complete_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateChecklistFilter {
            condition: ChecklistFilterConditionPB::IsComplete,
        },
        AssertNumberOfVisibleRows { expected: 1 },
    ];
    test.run_scripts(scripts).await;
}
