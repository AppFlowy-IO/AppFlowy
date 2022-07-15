use crate::services::row::GridBlockSnapshot;
use crate::services::tasks::queue::TaskHandlerId;
use std::cmp::Ordering;

#[derive(Eq, Debug, Clone, Copy)]
pub enum TaskType {
    /// Remove the row if it doesn't satisfy the filter.
    Filter,
    /// Generate snapshot for grid, unused by now.
    Snapshot,
}

impl PartialEq for TaskType {
    fn eq(&self, other: &Self) -> bool {
        matches!(
            (self, other),
            (Self::Filter, Self::Filter) | (Self::Snapshot, Self::Snapshot)
        )
    }
}

pub type TaskId = u32;

#[derive(Eq, Debug, Clone, Copy)]
pub struct PendingTask {
    pub ty: TaskType,
    pub id: TaskId,
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
        match (self.ty, other.ty) {
            (TaskType::Snapshot, TaskType::Snapshot) => Ordering::Equal,
            (TaskType::Snapshot, _) => Ordering::Greater,
            (_, TaskType::Snapshot) => Ordering::Less,
            (TaskType::Filter, TaskType::Filter) => self.id.cmp(&other.id).reverse(),
        }
    }
}

pub(crate) struct FilterTaskContext {
    pub blocks: Vec<GridBlockSnapshot>,
}

pub(crate) enum TaskContent {
    #[allow(dead_code)]
    Snapshot,
    Filter(FilterTaskContext),
}

pub(crate) struct Task {
    pub handler_id: TaskHandlerId,
    pub id: TaskId,
    pub content: TaskContent,
}

impl Task {
    pub fn is_finished(&self) -> bool {
        todo!()
    }
}
