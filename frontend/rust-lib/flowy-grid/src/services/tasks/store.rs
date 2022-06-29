use crate::services::tasks::task::Task;
use crate::services::tasks::TaskId;
use std::collections::HashMap;
use std::sync::atomic::AtomicU32;
use std::sync::atomic::Ordering::SeqCst;

pub struct GridTaskStore {
    tasks: HashMap<TaskId, Task>,
    task_id_counter: AtomicU32,
}

impl GridTaskStore {
    pub fn new() -> Self {
        Self {
            tasks: HashMap::new(),
            task_id_counter: AtomicU32::new(0),
        }
    }

    pub fn insert_task(&mut self, task: Task) {
        self.tasks.insert(task.id, task);
    }

    pub fn remove_task(&mut self, task_id: &TaskId) -> Option<Task> {
        self.tasks.remove(task_id)
    }

    pub fn next_task_id(&self) -> TaskId {
        let _ = self.task_id_counter.fetch_add(1, SeqCst);
        self.task_id_counter.load(SeqCst)
    }
}
