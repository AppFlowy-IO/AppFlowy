use anyhow::Error;
use futures::stream::FuturesUnordered;
use futures::StreamExt;
use lib_infra::async_trait::async_trait;

use lib_infra::priority_task::{
  Task, TaskContent, TaskDispatcher, TaskHandler, TaskId, TaskResult, TaskRunner, TaskState,
};
use lib_infra::ref_map::RefCountValue;
use rand::Rng;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::oneshot::Receiver;
use tokio::sync::RwLock;

pub enum SearchScript {
  AddTask {
    task: Task,
  },
  AddTasks {
    tasks: Vec<Task>,
  },
  #[allow(dead_code)]
  Wait {
    millisecond: u64,
  },
  CancelTask {
    task_id: TaskId,
  },
  UnregisterHandler {
    handler_id: String,
  },
  AssertTaskStatus {
    task_id: TaskId,
    expected_status: TaskState,
  },
  AssertExecuteOrder {
    execute_order: Vec<u32>,
    rets: Vec<Receiver<TaskResult>>,
  },
}

pub struct SearchTest {
  scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl SearchTest {
  pub async fn new() -> Self {
    let duration = Duration::from_millis(1000);
    let mut scheduler = TaskDispatcher::new(duration);
    scheduler.register_handler(Arc::new(MockTextTaskHandler()));
    scheduler.register_handler(Arc::new(MockBlobTaskHandler()));
    scheduler.register_handler(Arc::new(MockTimeoutTaskHandler()));

    let scheduler = Arc::new(RwLock::new(scheduler));
    tokio::spawn(TaskRunner::run(scheduler.clone()));

    Self { scheduler }
  }

  pub async fn next_task_id(&self) -> TaskId {
    self.scheduler.read().await.next_task_id()
  }

  pub async fn run_scripts(&self, scripts: Vec<SearchScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&self, script: SearchScript) {
    match script {
      SearchScript::AddTask { task } => {
        self.scheduler.write().await.add_task(task);
      },
      SearchScript::CancelTask { task_id } => {
        self.scheduler.write().await.cancel_task(task_id);
      },
      SearchScript::AddTasks { tasks } => {
        let mut scheduler = self.scheduler.write().await;
        for task in tasks {
          scheduler.add_task(task);
        }
      },
      SearchScript::Wait { millisecond } => {
        tokio::time::sleep(Duration::from_millis(millisecond)).await;
      },
      SearchScript::UnregisterHandler { handler_id } => {
        self
          .scheduler
          .write()
          .await
          .unregister_handler(handler_id)
          .await;
      },
      SearchScript::AssertTaskStatus {
        task_id,
        expected_status,
      } => {
        let status = self
          .scheduler
          .read()
          .await
          .read_task(&task_id)
          .unwrap()
          .state()
          .clone();
        assert_eq!(status, expected_status);
      },
      SearchScript::AssertExecuteOrder {
        execute_order,
        rets,
      } => {
        let mut futures = FuturesUnordered::new();
        for ret in rets {
          futures.push(ret);
        }
        let mut orders = vec![];
        while let Some(Ok(result)) = futures.next().await {
          orders.push(result.id);
          assert!(result.state.is_done());
        }
        assert_eq!(execute_order, orders);
      },
    }
  }
}

pub struct MockTextTaskHandler();
#[async_trait]
impl RefCountValue for MockTextTaskHandler {
  async fn did_remove(&self) {}
}

#[async_trait]
impl TaskHandler for MockTextTaskHandler {
  fn handler_id(&self) -> &str {
    "1"
  }

  async fn run(&self, content: TaskContent) -> Result<(), Error> {
    let millisecond = rand::thread_rng().gen_range(1..50);
    match content {
      TaskContent::Text(_s) => {
        tokio::time::sleep(Duration::from_millis(millisecond)).await;
      },
      TaskContent::Blob(_) => panic!("Only support text"),
    }
    Ok(())
  }
}

pub fn make_text_background_task(task_id: TaskId, s: &str) -> (Task, Receiver<TaskResult>) {
  let mut task = Task::background("1", task_id, TaskContent::Text(s.to_owned()));
  let recv = task.recv.take().unwrap();
  (task, recv)
}

pub fn make_text_user_interactive_task(task_id: TaskId, s: &str) -> (Task, Receiver<TaskResult>) {
  let mut task = Task::user_interactive("1", task_id, TaskContent::Text(s.to_owned()));
  let recv = task.recv.take().unwrap();
  (task, recv)
}

pub struct MockBlobTaskHandler();
#[async_trait]
impl RefCountValue for MockBlobTaskHandler {
  async fn did_remove(&self) {}
}

#[async_trait]
impl TaskHandler for MockBlobTaskHandler {
  fn handler_id(&self) -> &str {
    "2"
  }

  async fn run(&self, content: TaskContent) -> Result<(), Error> {
    match content {
      TaskContent::Text(_) => panic!("Only support blob"),
      TaskContent::Blob(bytes) => {
        let _msg = String::from_utf8(bytes).unwrap();
        tokio::time::sleep(Duration::from_millis(20)).await;
      },
    }
    Ok(())
  }
}

pub struct MockTimeoutTaskHandler();

#[async_trait]
impl TaskHandler for MockTimeoutTaskHandler {
  fn handler_id(&self) -> &str {
    "3"
  }

  async fn run(&self, content: TaskContent) -> Result<(), Error> {
    match content {
      TaskContent::Text(_) => panic!("Only support blob"),
      TaskContent::Blob(_bytes) => {
        tokio::time::sleep(Duration::from_millis(2000)).await;
      },
    }
    Ok(())
  }
}

pub fn make_timeout_task(task_id: TaskId) -> (Task, Receiver<TaskResult>) {
  let mut task = Task::background("3", task_id, TaskContent::Blob(vec![]));
  let recv = task.recv.take().unwrap();
  (task, recv)
}
