use crate::search_test::script::{make_background_task, make_user_interactive_task, SearchScript::*, SearchTest};
use flowy_search::TaskContent;
use futures::stream::FuturesOrdered;
use futures::StreamExt;

#[tokio::test]
async fn task_add_single_background_task_test() {
    let test = SearchTest::new().await;
    let (task, ret) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![AddTask { task }]).await;

    let result = ret.await.unwrap();
    assert!(result.is_done())
}

#[tokio::test]
async fn task_add_multiple_background_tasks_test() {
    let test = SearchTest::new().await;
    let (task_1, ret_1) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_2, ret_2) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_3, ret_3) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![
        AddTask { task: task_1 },
        AddTask { task: task_2 },
        AddTask { task: task_3 },
        AssertExecuteOrder {
            execute_order: vec![3, 2, 1],
            rets: vec![ret_1, ret_2, ret_3],
        },
    ])
    .await;
}

#[tokio::test]
async fn task_add_multiple_user_interactive_tasks_test() {
    let test = SearchTest::new().await;
    let (task_1, ret_1) = make_user_interactive_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_2, ret_2) = make_user_interactive_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_3, ret_3) = make_user_interactive_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![
        AddTask { task: task_1 },
        AddTask { task: task_2 },
        AddTask { task: task_3 },
        AssertExecuteOrder {
            execute_order: vec![3, 2, 1],
            rets: vec![ret_1, ret_2, ret_3],
        },
    ])
    .await;
}
#[tokio::test]
async fn task_add_multiple_different_kind_tasks_test() {
    let test = SearchTest::new().await;
    let (task_1, ret_1) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_2, ret_2) = make_user_interactive_task(test.next_task_id().await, TaskContent::Snapshot);
    let (task_3, ret_3) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![
        AddTask { task: task_1 },
        AddTask { task: task_2 },
        AddTask { task: task_3 },
        AssertExecuteOrder {
            execute_order: vec![2, 3, 1],
            rets: vec![ret_1, ret_2, ret_3],
        },
    ])
    .await;
}

#[tokio::test]
async fn task_add_multiple_different_kind_tasks_test2() {
    let test = SearchTest::new().await;
    let mut tasks = vec![];
    let mut rets = vec![];

    for i in 0..10 {
        let (task, ret) = if i % 2 == 0 {
            make_background_task(test.next_task_id().await, TaskContent::Snapshot)
        } else {
            make_user_interactive_task(test.next_task_id().await, TaskContent::Snapshot)
        };
        tasks.push(task);
        rets.push(ret);
    }

    test.run_scripts(vec![
        AddTasks { tasks },
        AssertExecuteOrder {
            execute_order: vec![10, 8, 6, 4, 2, 9, 7, 5, 3, 1],
            rets,
        },
    ])
    .await;
}
