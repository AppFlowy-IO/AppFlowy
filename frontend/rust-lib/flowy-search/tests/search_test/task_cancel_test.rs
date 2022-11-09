use crate::search_test::script::SearchScript::*;
use crate::search_test::script::{make_background_task, SearchTest};
use flowy_search::TaskContent;

#[tokio::test]
async fn task_add_single_background_task_test() {
    let test = SearchTest::new().await;
    let (task, ret) = make_background_task(test.next_task_id().await, TaskContent::Snapshot);
    test.run_scripts(vec![AddTask { task }]).await;

    let result = ret.await.unwrap();
    assert!(result.is_done())
}
