use crate::chat_manager::ChatUserService;
use crate::entities::{CompleteTextPB, CompleteTextTaskPB, CompletionTypePB};
use allo_isolate::Isolate;

use dashmap::DashMap;
use flowy_chat_pub::cloud::{ChatCloudService, CompletionType};
use flowy_error::{FlowyError, FlowyResult};

use futures::{SinkExt, StreamExt};
use lib_infra::isolate_stream::IsolateSink;

use std::sync::{Arc, Weak};
use tokio::select;


pub struct AITools {
  tasks: Arc<DashMap<String, tokio::sync::mpsc::Sender<()>>>,
  cloud_service: Weak<dyn ChatCloudService>,
  user_service: Weak<dyn ChatUserService>,
}

impl AITools {
  pub fn new(
    cloud_service: Weak<dyn ChatCloudService>,
    user_service: Weak<dyn ChatUserService>,
  ) -> Self {
    Self {
      tasks: Arc::new(DashMap::new()),
      cloud_service,
      user_service,
    }
  }

  pub async fn create_complete_task(
    &self,
    complete: CompleteTextPB,
  ) -> FlowyResult<CompleteTextTaskPB> {
    let workspace_id = self
      .user_service
      .upgrade()
      .ok_or_else(FlowyError::internal)?
      .workspace_id()?;
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let task = ToolTask::new(workspace_id, complete, self.cloud_service.clone(), rx);
    let task_id = task.task_id.clone();
    self.tasks.insert(task_id.clone(), tx);

    task.start().await;
    Ok(CompleteTextTaskPB { task_id })
  }

  pub async fn cancel_complete_task(&self, task_id: &str) {
    if let Some(entry) = self.tasks.remove(task_id) {
      let _ = entry.1.send(()).await;
    }
  }
}

pub struct ToolTask {
  workspace_id: String,
  task_id: String,
  stop_rx: tokio::sync::mpsc::Receiver<()>,
  context: CompleteTextPB,
  cloud_service: Weak<dyn ChatCloudService>,
}

impl ToolTask {
  pub fn new(
    workspace_id: String,
    context: CompleteTextPB,
    cloud_service: Weak<dyn ChatCloudService>,
    stop_rx: tokio::sync::mpsc::Receiver<()>,
  ) -> Self {
    Self {
      workspace_id,
      task_id: uuid::Uuid::new_v4().to_string(),
      context,
      cloud_service,
      stop_rx,
    }
  }

  pub async fn start(mut self) {
    tokio::spawn(async move {
      let mut sink = IsolateSink::new(Isolate::new(self.context.stream_port));

      if let Some(cloud_service) = self.cloud_service.upgrade() {
        let complete_type = match self.context.completion_type {
          CompletionTypePB::UnknownCompletionType | CompletionTypePB::ImproveWriting => {
            CompletionType::ImproveWriting
          },
          CompletionTypePB::SpellingAndGrammar => CompletionType::SpellingAndGrammar,
          CompletionTypePB::MakeShorter => CompletionType::MakeShorter,
          CompletionTypePB::MakeLonger => CompletionType::MakeLonger,
          CompletionTypePB::ContinueWriting => CompletionType::ContinueWriting,
        };

        let _ = sink.send("start:".to_string()).await;
        match cloud_service
          .stream_complete(&self.workspace_id, &self.context.text, complete_type)
          .await
        {
          Ok(mut stream) => loop {
            select! {
                _ = self.stop_rx.recv() => {
                    return;
                },
                result = stream.next() => {
                    match result {
                        Some(Ok(data)) => {
                            let s = String::from_utf8(data.to_vec()).unwrap_or_default();
                            let _ = sink.send(format!("data:{}", s)).await;
                        },
                        Some(Err(error)) => {
                            handle_error(&mut sink, FlowyError::from(error)).await;
                            return;
                        },
                        None => {
                            let _ = sink.send(format!("finish:{}", self.task_id)).await;
                            return;
                        },
                    }
                }
            }
          },
          Err(error) => {
            handle_error(&mut sink, error).await;
          },
        }
      }
    });
  }
}
async fn handle_error(sink: &mut IsolateSink, error: FlowyError) {
  if error.is_ai_response_limit_exceeded() {
    let _ = sink.send("AI_RESPONSE_LIMIT".to_string()).await;
  } else {
    let _ = sink.send(format!("error:{}", error)).await;
  }
}
