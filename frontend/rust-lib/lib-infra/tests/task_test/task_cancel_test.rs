use crate::task_test::script::SearchScript::*;
use crate::task_test::script::{make_text_background_task, make_timeout_task, SearchTest};
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskState};

#[tokio::test]
async fn task_cancel_background_task_test() {
  let test = SearchTest::new().await;
  let (task_1, ret_1) = make_text_background_task(test.next_task_id().await, "Hello world");
  let (task_2, ret_2) = make_text_background_task(test.next_task_id().await, "");
  test
    .run_scripts(vec![
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

#[tokio::test]
async fn task_with_empty_handler_id_test() {
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
  assert_eq!(result.state, TaskState::Cancel);
}

#[tokio::test]
async fn task_can_not_find_handler_test() {
  let test = SearchTest::new().await;
  let (task, ret) = make_text_background_task(test.next_task_id().await, "Hello world");
  let handler_id = task.handler_id.clone();
  test
    .run_scripts(vec![UnregisterHandler { handler_id }, AddTask { task }])
    .await;

  let result = ret.await.unwrap();
  assert_eq!(result.state, TaskState::Cancel);
}

#[tokio::test]
async fn task_can_not_find_handler_test2() {
  let test = SearchTest::new().await;
  let mut tasks = vec![];
  let mut rets = vec![];
  let handler_id = "1".to_owned();
  for _i in 1..10000 {
    let (task, ret) = make_text_background_task(test.next_task_id().await, "");
    tasks.push(task);
    rets.push(ret);
  }

  test
    .run_scripts(vec![UnregisterHandler { handler_id }, AddTasks { tasks }])
    .await;
}

#[tokio::test]
async fn task_run_timeout_test() {
  let test = SearchTest::new().await;
  let (task, ret) = make_timeout_task(test.next_task_id().await);
  test.run_scripts(vec![AddTask { task }]).await;

  let result = ret.await.unwrap();
  assert_eq!(result.state, TaskState::Timeout);
}
