#![allow(clippy::all)]
#![allow(dead_code)]
use crate::services::row::GridBlockSnapshot;
use crate::services::tasks::queue::TaskHandlerId;
use std::cmp::Ordering;

#[derive(Eq, Debug, Clone, Copy)]
pub enum TaskType {
    /// Remove the row if it doesn't satisfy the filter.
    Filter,
    /// Generate snapshot for grid, unused by now.
    Snapshot,

    Group,
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
            // Snapshot
            (TaskType::Snapshot, TaskType::Snapshot) => Ordering::Equal,
            (TaskType::Snapshot, _) => Ordering::Greater,
            (_, TaskType::Snapshot) => Ordering::Less,
            // Group
            (TaskType::Group, TaskType::Group) => self.id.cmp(&other.id).reverse(),
            (TaskType::Group, _) => Ordering::Greater,
            (_, TaskType::Group) => Ordering::Greater,
            // Filter
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
    Group,
    Filter(FilterTaskContext),
}

#[derive(Debug, Eq, PartialEq)]
pub(crate) enum TaskStatus {
    Pending,
    Processing,
    Done,
    Failure,
    Cancel,
}

pub(crate) struct Task {
    pub id: TaskId,
    pub handler_id: TaskHandlerId,
    pub content: Option<TaskContent>,
    status: TaskStatus,
    pub ret: Option<tokio::sync::oneshot::Sender<TaskResult>>,
    pub rx: Option<tokio::sync::oneshot::Receiver<TaskResult>>,
}

pub(crate) struct TaskResult {
    pub id: TaskId,
    pub(crate) status: TaskStatus,
}

impl std::convert::From<Task> for TaskResult {
    fn from(task: Task) -> Self {
        TaskResult {
            id: task.id,
            status: task.status,
        }
    }
}

impl Task {
    pub fn new(handler_id: &str, id: TaskId, content: TaskContent) -> Self {
        let (ret, rx) = tokio::sync::oneshot::channel();
        Self {
            handler_id: handler_id.to_owned(),
            id,
            content: Some(content),
            ret: Some(ret),
            rx: Some(rx),
            status: TaskStatus::Pending,
        }
    }

    pub fn set_status(&mut self, status: TaskStatus) {
        self.status = status;
    }

    pub fn is_finished(&self) -> bool {
        match self.status {
            TaskStatus::Done => true,
            _ => false,
        }
    }
}
