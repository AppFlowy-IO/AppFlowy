use crate::services::tasks::task::{PendingTask, Task, TaskContent, TaskType};
use atomic_refcell::AtomicRefCell;

use std::cmp::Ordering;
use std::collections::hash_map::Entry;
use std::collections::{BinaryHeap, HashMap};
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

#[derive(Default)]
pub(crate) struct GridTaskQueue {
    // index_tasks for quick access
    index_tasks: HashMap<TaskHandlerId, Arc<AtomicRefCell<TaskList>>>,
    queue: BinaryHeap<Arc<AtomicRefCell<TaskList>>>,
}

impl GridTaskQueue {
    pub(crate) fn new() -> Self {
        Self::default()
    }

    pub(crate) fn push(&mut self, task: &Task) {
        let task_type = match task.content {
            TaskContent::Snapshot => TaskType::Snapshot,
            TaskContent::Filter { .. } => TaskType::Filter,
        };
        let pending_task = PendingTask {
            ty: task_type,
            id: task.id,
        };
        match self.index_tasks.entry("1".to_owned()) {
            Entry::Occupied(entry) => {
                let mut list = entry.get().borrow_mut();
                assert!(list.peek().map(|old_id| pending_task.id >= old_id.id).unwrap_or(true));
                list.push(pending_task);
            }
            Entry::Vacant(entry) => {
                let mut task_list = TaskList::new(entry.key());
                task_list.push(pending_task);
                let task_list = Arc::new(AtomicRefCell::new(task_list));
                entry.insert(task_list.clone());
                self.queue.push(task_list);
            }
        }
    }

    pub(crate) fn mut_head<T, F>(&mut self, mut f: F) -> Option<T>
    where
        F: FnMut(&mut TaskList) -> Option<T>,
    {
        let head = self.queue.pop()?;
        let result = {
            let mut ref_head = head.borrow_mut();
            f(&mut *ref_head)
        };
        if !head.borrow().tasks.is_empty() {
            self.queue.push(head);
        } else {
            self.index_tasks.remove(&head.borrow().id);
        }
        result
    }
}

pub type TaskHandlerId = String;

#[derive(Debug)]
pub(crate) struct TaskList {
    pub(crate) id: TaskHandlerId,
    tasks: BinaryHeap<PendingTask>,
}

impl Deref for TaskList {
    type Target = BinaryHeap<PendingTask>;

    fn deref(&self) -> &Self::Target {
        &self.tasks
    }
}

impl DerefMut for TaskList {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.tasks
    }
}

impl TaskList {
    fn new(id: &str) -> Self {
        Self {
            id: id.to_owned(),
            tasks: BinaryHeap::new(),
        }
    }
}

impl PartialEq for TaskList {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Eq for TaskList {}

impl Ord for TaskList {
    fn cmp(&self, other: &Self) -> Ordering {
        match (self.peek(), other.peek()) {
            (None, None) => Ordering::Equal,
            (None, Some(_)) => Ordering::Less,
            (Some(_), None) => Ordering::Greater,
            (Some(lhs), Some(rhs)) => lhs.cmp(rhs),
        }
    }
}

impl PartialOrd for TaskList {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
