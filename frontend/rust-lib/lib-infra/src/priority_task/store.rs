use crate::priority_task::{Task, TaskId, TaskState};
use std::collections::HashMap;
use std::mem;
use std::sync::atomic::AtomicU32;
use std::sync::atomic::Ordering::SeqCst;

pub(crate) struct TaskStore {
  tasks: HashMap<TaskId, Task>,
  task_id_counter: AtomicU32,
}

impl TaskStore {
  pub fn new() -> Self {
    Self {
      tasks: HashMap::new(),
      task_id_counter: AtomicU32::new(0),
    }
  }

  pub(crate) fn insert_task(&mut self, task: Task) {
    self.tasks.insert(task.id, task);
  }

  pub(crate) fn remove_task(&mut self, task_id: &TaskId) -> Option<Task> {
    self.tasks.remove(task_id)
  }

  pub(crate) fn mut_task(&mut self, task_id: &TaskId) -> Option<&mut Task> {
    self.tasks.get_mut(task_id)
  }

  pub(crate) fn read_task(&self, task_id: &TaskId) -> Option<&Task> {
    self.tasks.get(task_id)
  }

  pub(crate) fn clear(&mut self) {
    let tasks = mem::take(&mut self.tasks);
    tasks.into_values().for_each(|mut task| {
      if task.ret.is_some() {
        let ret = task.ret.take().unwrap();
        task.set_state(TaskState::Cancel);
        let _ = ret.send(task.into());
      }
    });
  }

  pub(crate) fn next_task_id(&self) -> TaskId {
    let _ = self.task_id_counter.fetch_add(1, SeqCst);
    self.task_id_counter.load(SeqCst)
  }
}
