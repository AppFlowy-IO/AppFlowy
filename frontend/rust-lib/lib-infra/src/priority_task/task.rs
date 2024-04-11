use crate::priority_task::TaskHandlerId;
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
      (QualityOfService::UserInteractive, QualityOfService::UserInteractive) => {
        self.id.cmp(&other.id)
      },
      (QualityOfService::UserInteractive, _) => Ordering::Greater,
      (_, QualityOfService::UserInteractive) => Ordering::Less,
      // background
      (QualityOfService::Background, QualityOfService::Background) => self.id.cmp(&other.id),
    }
  }
}

#[derive(Debug, Clone)]
pub enum TaskContent {
  Text(String),
  Blob(Vec<u8>),
}

#[derive(Debug, Eq, PartialEq, Clone)]
pub enum TaskState {
  Pending,
  Processing,
  Done,
  Failure,
  Cancel,
  Timeout,
}

impl TaskState {
  pub fn is_pending(&self) -> bool {
    matches!(self, TaskState::Pending)
  }
  pub fn is_done(&self) -> bool {
    matches!(self, TaskState::Done)
  }
  pub fn is_cancel(&self) -> bool {
    matches!(self, TaskState::Cancel)
  }

  pub fn is_processing(&self) -> bool {
    matches!(self, TaskState::Processing)
  }

  pub fn is_failed(&self) -> bool {
    matches!(self, TaskState::Failure)
  }
}

pub struct Task {
  pub id: TaskId,
  pub handler_id: TaskHandlerId,
  pub content: Option<TaskContent>,
  pub qos: QualityOfService,
  state: TaskState,
  pub ret: Option<Sender<TaskResult>>,
  pub recv: Option<Receiver<TaskResult>>,
}

impl Task {
  pub fn background(handler_id: &str, id: TaskId, content: TaskContent) -> Self {
    Self::new(handler_id, id, content, QualityOfService::Background)
  }

  pub fn user_interactive(handler_id: &str, id: TaskId, content: TaskContent) -> Self {
    Self::new(handler_id, id, content, QualityOfService::UserInteractive)
  }

  pub fn new(handler_id: &str, id: TaskId, content: TaskContent, qos: QualityOfService) -> Self {
    let handler_id = handler_id.to_owned();
    let (ret, recv) = tokio::sync::oneshot::channel();
    Self {
      handler_id,
      id,
      content: Some(content),
      qos,
      ret: Some(ret),
      recv: Some(recv),
      state: TaskState::Pending,
    }
  }

  pub fn state(&self) -> &TaskState {
    &self.state
  }

  pub(crate) fn set_state(&mut self, status: TaskState) {
    self.state = status;
  }
}

pub struct TaskResult {
  pub id: TaskId,
  pub state: TaskState,
}

impl std::convert::From<Task> for TaskResult {
  fn from(task: Task) -> Self {
    TaskResult {
      id: task.id,
      state: task.state().clone(),
    }
  }
}
