use crate::TaskHandlerId;
use std::cmp::Ordering;
use tokio::sync::oneshot::{Receiver, Sender};

#[derive(Eq, Debug, Clone, Copy)]
pub enum QualityOfService {
    Background,
    UserInteractive,
}

impl PartialEq for QualityOfService {
    fn eq(&self, other: &Self) -> bool {
        matches!(
            (self, other),
            (Self::Background, Self::Background) | (Self::UserInteractive, Self::UserInteractive)
        )
    }
}

pub type TaskId = u32;

#[derive(Eq, Debug, Clone, Copy)]
pub struct PendingTask {
    pub qos: QualityOfService,
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
        match (self.qos, other.qos) {
            // User interactive
            (QualityOfService::UserInteractive, QualityOfService::UserInteractive) => Ordering::Equal,
            (QualityOfService::UserInteractive, _) => Ordering::Greater,
            (_, QualityOfService::UserInteractive) => Ordering::Less,
            // background
            (QualityOfService::Background, QualityOfService::Background) => self.id.cmp(&other.id).reverse(),
        }
    }
}

pub enum TaskContent {
    Snapshot,
    Filter(String),
}

#[derive(Debug, Eq, PartialEq)]
pub enum TaskStatus {
    Pending,
    Processing,
    Done,
    Failure,
    Cancel,
}

pub struct Task<T> {
    pub id: TaskId,
    pub handler_id: TaskHandlerId,
    pub content: Option<TaskContent>,
    pub qos: QualityOfService,
    status: TaskStatus,
    pub ret: Option<Sender<TaskResult>>,
    pub recv: Option<Receiver<TaskResult>>,
}

impl Task {
    pub fn new(handler_id: &str, id: TaskId, content: TaskContent, qos: QualityOfService) -> Self {
        let (ret, recv) = tokio::sync::oneshot::channel();
        Self {
            handler_id: handler_id.to_owned(),
            id,
            content: Some(content),
            qos,
            ret: Some(ret),
            recv: Some(recv),
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

// pub struct TaskBuilder {
//     task: Task,
// }
//
// impl TaskBuilder {
//     pub fn new(handler_id: &str, task_id: TaskId) -> Self {
//         Self {
//             task: Task::new(handler_id, task_id, TaskContent::Empty, QualityOfService::Background),
//         }
//     }
//
// }

pub struct TaskResult {
    pub id: TaskId,
    pub status: TaskStatus,
}

impl TaskResult {
    pub fn is_pending(&self) -> bool {
        match self.status {
            TaskStatus::Pending => true,
            _ => false,
        }
    }
    pub fn is_done(&self) -> bool {
        match self.status {
            TaskStatus::Done => true,
            _ => false,
        }
    }
    pub fn is_cancel(&self) -> bool {
        match self.status {
            TaskStatus::Cancel => true,
            _ => false,
        }
    }

    pub fn is_processing(&self) -> bool {
        match self.status {
            TaskStatus::Processing => true,
            _ => false,
        }
    }

    pub fn is_failed(&self) -> bool {
        match self.status {
            TaskStatus::Failure => true,
            _ => false,
        }
    }
}

impl std::convert::From<Task> for TaskResult {
    fn from(task: Task) -> Self {
        TaskResult {
            id: task.id,
            status: task.status,
        }
    }
}
