use crate::grid::filter_test::script::FilterScript::*;
use crate::grid::filter_test::script::GridFilterTest;
use flowy_grid::entities::DateFilterCondition;

#[tokio::test]
#[should_panic]
async fn grid_filter_date_is_check_test() {
    let mut test = GridFilterTest::new().await;
    let scripts = vec![
        CreateDateFilter {
            condition: DateFilterCondition::DateIs,
            content: "1647251762".to_string(),
        },
        AssertNumberOfRows { expected: 2 },
    ];
    test.run_scripts(scripts).await;
}
