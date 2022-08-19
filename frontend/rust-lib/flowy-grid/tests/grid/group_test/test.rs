use crate::grid::group_test::script::GridGroupTest;
use crate::grid::group_test::script::GroupScript::*;

#[tokio::test]
async fn board_init_test() {
    let mut test = GridGroupTest::new().await;
    let scripts = vec![
        AssertGroupCount(3),
        AssertGroup {
            group_index: 0,
            row_count: 2,
        },
        AssertGroup {
            group_index: 1,
            row_count: 2,
        },
        AssertGroup {
            group_index: 2,
            row_count: 1,
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn board_move_row_test() {
    let mut test = GridGroupTest::new().await;
    let group = test.group_at_index(0).await;
    let scripts = vec![
        MoveRow {
            from_group_index: 0,
            from_row_index: 0,
            to_group_index: 0,
            to_row_index: 1,
        },
        AssertGroup {
            group_index: 0,
            row_count: 2,
        },
        AssertGroupRow {
            group_index: 0,
            row_index: 1,
            row: group.rows.get(0).unwrap().clone(),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn board_move_row_to_other_group_test() {
    let mut test = GridGroupTest::new().await;
    let group = test.group_at_index(0).await;
    let scripts = vec![
        MoveRow {
            from_group_index: 0,
            from_row_index: 0,
            to_group_index: 1,
            to_row_index: 1,
        },
        AssertGroup {
            group_index: 0,
            row_count: 1,
        },
        AssertGroup {
            group_index: 1,
            row_count: 3,
        },
        AssertGroupRow {
            group_index: 1,
            row_index: 1,
            row: group.rows.get(0).unwrap().clone(),
        },
    ];
    test.run_scripts(scripts).await;
}

#[tokio::test]
async fn board_move_row_to_other_group_and_reorder_test() {
    let mut test = GridGroupTest::new().await;
    let group = test.group_at_index(0).await;
    let scripts = vec![
        MoveRow {
            from_group_index: 0,
            from_row_index: 0,
            to_group_index: 1,
            to_row_index: 1,
        },
        MoveRow {
            from_group_index: 1,
            from_row_index: 1,
            to_group_index: 1,
            to_row_index: 2,
        },
        AssertGroupRow {
            group_index: 1,
            row_index: 2,
            row: group.rows.get(0).unwrap().clone(),
        },
    ];
    test.run_scripts(scripts).await;
}
