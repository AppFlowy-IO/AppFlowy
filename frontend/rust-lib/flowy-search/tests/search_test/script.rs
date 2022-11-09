use anyhow::Error;
use anyhow::Result;
use flowy_search::{QualityOfService, Task, TaskContent, TaskHandler, TaskId, TaskResult, TaskScheduler};
use lib_infra::future::BoxResultFuture;
use lib_infra::ref_map::RefCountValue;
use rand::Rng;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::oneshot::Receiver;
use tokio::sync::RwLock;
use tokio::time::interval;

pub enum SearchScript {
    AddTask { task: Task },
}

pub struct SearchTest {
    scheduler: Arc<RwLock<TaskScheduler>>,
}

impl SearchTest {
    pub async fn new() -> Self {
        let scheduler = TaskScheduler::new();
        scheduler
            .write()
            .await
            .register_handler(Arc::new(MockSnapshotTaskHandler()));

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
        }
    }
}

pub struct MockSnapshotTaskHandler();

impl RefCountValue for MockSnapshotTaskHandler {
    fn did_remove(&self) {}
}

impl TaskHandler for MockSnapshotTaskHandler {
    fn handler_id(&self) -> &str {
        "snapshot"
    }

    fn run(&self, _content: TaskContent) -> BoxResultFuture<(), Error> {
        let mut rng = rand::thread_rng();
        let millisecond = rng.gen_range(0..1000);
        Box::pin(async move {
            tokio::time::sleep(Duration::from_millis(millisecond)).await;
            Ok(())
        })
    }
}

pub fn make_snapshot_task(task_id: TaskId, content: TaskContent) -> (Task, Receiver<TaskResult>) {
    let mut task = Task::new("snapshot", task_id, content, QualityOfService::Background);
    let recv = task.recv.take().unwrap();
    (task, recv)
}
