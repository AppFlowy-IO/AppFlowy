use crate::task_test::script::{
  make_text_background_task, make_text_user_interactive_task, SearchScript::*, SearchTest,
};

#[tokio::test]
async fn task_add_single_background_task_test() {
  let test = SearchTest::new().await;
  let (task, ret) = make_text_background_task(test.next_task_id().await, "");
  test.run_scripts(vec![AddTask { task }]).await;

  let result = ret.await.unwrap();
  assert!(result.state.is_done())
}

#[tokio::test]
async fn task_add_multiple_background_tasks_test() {
  let test = SearchTest::new().await;
  let (task_1, ret_1) = make_text_background_task(test.next_task_id().await, "");
  let (task_2, ret_2) = make_text_background_task(test.next_task_id().await, "");
  let (task_3, ret_3) = make_text_background_task(test.next_task_id().await, "");
  test
    .run_scripts(vec![
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
  let (task_1, ret_1) = make_text_user_interactive_task(test.next_task_id().await, "");
  let (task_2, ret_2) = make_text_user_interactive_task(test.next_task_id().await, "");
  let (task_3, ret_3) = make_text_user_interactive_task(test.next_task_id().await, "");
  test
    .run_scripts(vec![
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
  let (task_1, ret_1) = make_text_background_task(test.next_task_id().await, "");
  let (task_2, ret_2) = make_text_user_interactive_task(test.next_task_id().await, "");
  let (task_3, ret_3) = make_text_background_task(test.next_task_id().await, "");
  test
    .run_scripts(vec![
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
      make_text_background_task(test.next_task_id().await, "")
    } else {
      make_text_user_interactive_task(test.next_task_id().await, "")
    };
    tasks.push(task);
    rets.push(ret);
  }

  test
    .run_scripts(vec![
      AddTasks { tasks },
      AssertExecuteOrder {
        execute_order: vec![10, 8, 6, 4, 2, 9, 7, 5, 3, 1],
        rets,
      },
    ])
    .await;
}

// #[tokio::test]
// async fn task_add_1000_tasks_test() {
//     let test = SearchTest::new().await;
//     let mut tasks = vec![];
//     let mut execute_order = vec![];
//     let mut rets = vec![];
//
//     for i in 1..1000 {
//         let (task, ret) = make_text_background_task(test.next_task_id().await, "");
//         execute_order.push(i);
//         tasks.push(task);
//         rets.push(ret);
//     }
//     execute_order.reverse();
//
//     test.run_scripts(vec![AddTasks { tasks }, AssertExecuteOrder { execute_order, rets }])
//         .await;
// }
