use crate::ai_manager::AIUserService;
use crate::entities::{CompleteTextPB, CompleteTextTaskPB, CompletionTypePB};
use allo_isolate::Isolate;

use dashmap::DashMap;
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, CompleteTextParams, CompletionMetadata, CompletionStreamValue,
  CompletionType, CustomPrompt,
};
use flowy_error::{FlowyError, FlowyResult};

use futures::{SinkExt, StreamExt};
use lib_infra::isolate_stream::IsolateSink;

use crate::stream_message::StreamMessage;
use flowy_sqlite::kv::KVStorePreferences;
use std::sync::{Arc, Weak};
use tokio::select;
use tracing::info;

pub struct AICompletion {
  tasks: Arc<DashMap<String, tokio::sync::mpsc::Sender<()>>>,
  cloud_service: Weak<dyn ChatCloudService>,
  user_service: Weak<dyn AIUserService>,
}

impl AICompletion {
  pub fn new(
    cloud_service: Weak<dyn ChatCloudService>,
    user_service: Weak<dyn AIUserService>,
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
    preferred_model: Option<AIModel>,
  ) -> FlowyResult<CompleteTextTaskPB> {
    if matches!(complete.completion_type, CompletionTypePB::CustomPrompt)
      && complete.custom_prompt.is_none()
    {
      return Err(
        FlowyError::invalid_data()
          .with_context("custom_prompt is required when completion_type is CustomPrompt"),
      );
    }

    let workspace_id = self
      .user_service
      .upgrade()
      .ok_or_else(FlowyError::internal)?
      .workspace_id()?;
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let task = CompletionTask::new(
      workspace_id,
      complete,
      preferred_model,
      self.cloud_service.clone(),
      rx,
    );
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

pub struct CompletionTask {
  workspace_id: String,
  task_id: String,
  stop_rx: tokio::sync::mpsc::Receiver<()>,
  context: CompleteTextPB,
  cloud_service: Weak<dyn ChatCloudService>,
  preferred_model: Option<AIModel>,
}

impl CompletionTask {
  pub fn new(
    workspace_id: String,
    context: CompleteTextPB,
    preferred_model: Option<AIModel>,
    cloud_service: Weak<dyn ChatCloudService>,
    stop_rx: tokio::sync::mpsc::Receiver<()>,
  ) -> Self {
    Self {
      workspace_id,
      task_id: uuid::Uuid::new_v4().to_string(),
      context,
      cloud_service,
      stop_rx,
      preferred_model,
    }
  }

  pub async fn start(mut self) {
    tokio::spawn(async move {
      let mut sink = IsolateSink::new(Isolate::new(self.context.stream_port));

      if let Some(cloud_service) = self.cloud_service.upgrade() {
        let complete_type = match self.context.completion_type {
          CompletionTypePB::ImproveWriting => CompletionType::ImproveWriting,
          CompletionTypePB::SpellingAndGrammar => CompletionType::SpellingAndGrammar,
          CompletionTypePB::MakeShorter => CompletionType::MakeShorter,
          CompletionTypePB::MakeLonger => CompletionType::MakeLonger,
          CompletionTypePB::ContinueWriting => CompletionType::ContinueWriting,
          CompletionTypePB::ExplainSelected => CompletionType::Explain,
          CompletionTypePB::UserQuestion => CompletionType::UserQuestion,
          CompletionTypePB::CustomPrompt => CompletionType::CustomPrompt,
        };

        let _ = sink.send("start:".to_string()).await;
        let completion_history = Some(self.context.history.iter().map(Into::into).collect());
        let format = self.context.format.map(Into::into).unwrap_or_default();
        let params = CompleteTextParams {
          text: self.context.text,
          completion_type: Some(complete_type),
          metadata: Some(CompletionMetadata {
            object_id: self.context.object_id,
            workspace_id: Some(self.workspace_id.clone()),
            rag_ids: Some(self.context.rag_ids),
            completion_history,
            custom_prompt: self
              .context
              .custom_prompt
              .map(|v| CustomPrompt { system: v }),
          }),
          format,
        };

        info!("start completion: {:?}", params);
        match cloud_service
          .stream_complete(&self.workspace_id, params, self.preferred_model)
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
                      match data {
                        CompletionStreamValue::Answer{ value } => {
                          let _ = sink.send(format!("data:{}", value)).await;
                        }
                         CompletionStreamValue::Comment{ value } => {
                          let _ = sink.send(format!("comment:{}", value)).await;
                        }
                      }
                    },
                    Some(Err(error)) => {
                        handle_error(&mut sink, error).await;
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

async fn handle_error(sink: &mut IsolateSink, err: FlowyError) {
  if err.is_ai_response_limit_exceeded() {
    let _ = sink.send("AI_RESPONSE_LIMIT".to_string()).await;
  } else if err.is_ai_image_response_limit_exceeded() {
    let _ = sink.send("AI_IMAGE_RESPONSE_LIMIT".to_string()).await;
  } else if err.is_ai_max_required() {
    let _ = sink.send(format!("AI_MAX_REQUIRED:{}", err.msg)).await;
  } else if err.is_local_ai_not_ready() {
    let _ = sink.send(format!("LOCAL_AI_NOT_READY:{}", err.msg)).await;
  } else if err.is_local_ai_disabled() {
    let _ = sink.send(format!("LOCAL_AI_DISABLED:{}", err.msg)).await;
  } else {
    let _ = sink
      .send(StreamMessage::OnError(err.msg.clone()).to_string())
      .await;
  }
}
