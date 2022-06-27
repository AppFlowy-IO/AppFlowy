use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::ops::{Deref, DerefMut};

enum TaskType {
    /// Remove the row if it doesn't satisfy the filter.
    Filter,
    /// Generate snapshot for grid, unused by now.
    Snapshot,
}

/// Two tasks are equal if they have the same type.
impl PartialEq for TaskType {
    fn eq(&self, other: &Self) -> bool {
        matches!((self, other),)
    }
}

pub type TaskId = u32;

#[derive(Eq, Debug, Clone, Copy)]
struct PendingTask {
    kind: TaskType,
    id: TaskId,
}

impl PartialEq for PendingTask {
    fn eq(&self, other: &Self) -> bool {
        self.id.eq(&other.id)
    }
}

impl PartialOrd for PendingTask {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for PendingTask {
    fn cmp(&self, other: &Self) -> Ordering {
        self.id.cmp(&other.id).reverse()
    }
}

#[derive(PartialEq, Eq, Hash, Debug, Clone)]
enum TaskListIdentifier {
    Filter(String),
    Snapshot(String),
}

#[derive(Debug)]
struct TaskList {
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
    fn new() -> Self {
        Self {
            tasks: Default::default(),
        }
    }
}
