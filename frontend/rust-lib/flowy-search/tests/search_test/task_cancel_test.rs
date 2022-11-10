use crate::search_test::script::SearchScript::*;
use crate::search_test::script::{make_blob_background_task, make_text_background_task, SearchTest};
use flowy_search::{QualityOfService, Task, TaskContent, TaskState};

#[tokio::test]
async fn task_cancel_background_task_test() {
    let test = SearchTest::new().await;
    let (task_1, ret_1) = make_text_background_task(test.next_task_id().await, "Hello world");
    let (task_2, ret_2) = make_text_background_task(test.next_task_id().await, "");
    test.run_scripts(vec![
        AddTask { task: task_1 },
        AddTask { task: task_2 },
        AssertTaskStatus {
            task_id: 1,
            expected_status: TaskState::Pending,
        },
        AssertTaskStatus {
            task_id: 2,
            expected_status: TaskState::Pending,
        },
        CancelTask { task_id: 2 },
        AssertTaskStatus {
            task_id: 2,
            expected_status: TaskState::Cancel,
        },
    ])
    .await;

    let result = ret_1.await.unwrap();
    assert_eq!(result.state, TaskState::Done);

    let result = ret_2.await.unwrap();
    assert_eq!(result.state, TaskState::Cancel);
}
