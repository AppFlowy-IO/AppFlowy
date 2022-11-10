use crate::search_test::script::SearchScript::*;
use crate::search_test::script::{make_blob_background_task, make_text_background_task, make_timeout_task, SearchTest};
use flowy_search::{QualityOfService, Task, TaskContent, TaskState};

#[tokio::test]
async fn task_can_not_find_handler_test() {
    let test = SearchTest::new().await;
    let mut task = Task::new(
        "",
        test.next_task_id().await,
        TaskContent::Text("".to_owned()),
        QualityOfService::Background,
    );
    let ret = task.recv.take().unwrap();
    test.run_scripts(vec![AddTask { task }]).await;

    let result = ret.await.unwrap();
    assert_eq!(result.state, TaskState::Failure);
}

#[tokio::test]
async fn task_can_not_find_handler_test2() {
    let test = SearchTest::new().await;
    let (task, ret) = make_text_background_task(test.next_task_id().await, "Hello world");
    let handler_id = task.handler_id.clone();
    test.run_scripts(vec![UnregisterHandler { handler_id }, AddTask { task }])
        .await;

    let result = ret.await.unwrap();
    assert_eq!(result.state, TaskState::Failure);
}

#[tokio::test]
async fn task_run_timeout_test() {
    let test = SearchTest::new().await;
    let (task, ret) = make_timeout_task(test.next_task_id().await);
    test.run_scripts(vec![AddTask { task }]).await;

    let result = ret.await.unwrap();
    assert_eq!(result.state, TaskState::Timeout);
}
