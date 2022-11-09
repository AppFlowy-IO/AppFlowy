use anyhow::Error;
use anyhow::Result;
use flowy_search::{QualityOfService, Task, TaskContent, TaskHandler, TaskId, TaskResult, TaskScheduler};
use futures::stream::{FuturesOrdered, FuturesUnordered};
use futures::StreamExt;
use lib_infra::future::BoxResultFuture;
use lib_infra::ref_map::RefCountValue;
use rand::Rng;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::oneshot::Receiver;
use tokio::sync::RwLock;
use tokio::time::interval;

pub enum SearchScript {
    AddTask {
        task: Task,
    },
    AddTasks {
        tasks: Vec<Task>,
    },
    AssertExecuteOrder {
        execute_order: Vec<u32>,
        rets: Vec<Receiver<TaskResult>>,
    },
}

pub struct SearchTest {
    scheduler: Arc<RwLock<TaskScheduler>>,
}

impl SearchTest {
    pub async fn new() -> Self {
        let scheduler = TaskScheduler::new();
        scheduler.write().await.register_handler(Arc::new(MockTaskHandler()));

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
            }
            SearchScript::AddTasks { tasks } => {
                for task in tasks {
                    self.scheduler.write().await.add_task(task);
                }
            }
            SearchScript::AssertExecuteOrder { execute_order, rets } => {
                let mut futures = FuturesUnordered::new();
                for ret in rets {
                    futures.push(ret);
                }
                let mut orders = vec![];
                while let Some(Ok(result)) = futures.next().await {
                    orders.push(result.id);
                }
                assert_eq!(execute_order, orders);
            }
        }
    }
}

pub struct MockTaskHandler();
impl RefCountValue for MockTaskHandler {
    fn did_remove(&self) {}
}

impl TaskHandler for MockTaskHandler {
    fn handler_id(&self) -> &str {
        "1"
    }

    fn run(&self, _content: TaskContent) -> BoxResultFuture<(), Error> {
        let mut rng = rand::thread_rng();
        let millisecond = rng.gen_range(50..100);
        Box::pin(async move {
            tokio::time::sleep(Duration::from_millis(millisecond)).await;
            Ok(())
        })
    }
}

pub fn make_background_task(task_id: TaskId, content: TaskContent) -> (Task, Receiver<TaskResult>) {
    let mut task = Task::background("1", task_id, content);
    let recv = task.recv.take().unwrap();
    (task, recv)
}

pub fn make_user_interactive_task(task_id: TaskId, content: TaskContent) -> (Task, Receiver<TaskResult>) {
    let mut task = Task::user_interactive("1", task_id, content);
    let recv = task.recv.take().unwrap();
    (task, recv)
}
