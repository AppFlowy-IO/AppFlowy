use crate::search_test::script::{make_snapshot_task, SearchScript::*, SearchTest};
use flowy_search::TaskContent;

#[tokio::test]
async fn task_add_snapshot_task_test() {
    let test = SearchTest::new().await;
    let (task, ret) = make_snapshot_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![AddTask { task }]).await;

    let result = ret.await.unwrap();
    assert!(result.is_done())
}
#[tokio::test]
async fn task_add_multiple_snapshot_tasks_test() {
    let test = SearchTest::new().await;
    let (task_1, ret_1) = make_snapshot_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_2, ret_2) = make_snapshot_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_3, ret_3) = make_snapshot_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![
        AddTask { task: task_1 },
        AddTask { task: task_2 },
        AddTask { task: task_3 },
    ])
    .await;

    let result = ret_1.await.unwrap();
    assert!(result.is_done());

    let result = ret_2.await.unwrap();
    assert!(result.is_done());

    let result = ret_3.await.unwrap();
    assert!(result.is_done());
}
