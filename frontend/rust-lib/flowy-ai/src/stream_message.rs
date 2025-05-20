use serde::Serialize;
use std::fmt::Display;

#[allow(dead_code)]
pub enum StreamMessage {
  MessageId(i64),
  IndexStart,
  IndexEnd,
  OnData(String),
  OnFollowUp(AIFollowUpData),
  OnError(String),
  Metadata(String),
  Done,
  StartIndexFile { file_name: String },
  EndIndexFile { file_name: String },
  IndexFileError { file_name: String },
  AIResponseLimitExceeded,
  AIImageResponseLimitExceeded,
  AIMaxRequired(String),
  LocalAINotReady(String),
  LocalAIDisabled(String),
}

#[derive(Debug, Clone, Serialize, Default)]
pub struct AIFollowUpData {
  pub should_generate_related_question: bool,
}

impl Display for StreamMessage {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      StreamMessage::MessageId(message_id) => write!(f, "message_id:{}", message_id),
      StreamMessage::IndexStart => write!(f, "index_start:"),
      StreamMessage::IndexEnd => write!(f, "index_end"),
      StreamMessage::OnData(message) => write!(f, "data:{message}"),
      StreamMessage::OnError(message) => write!(f, "error:{message}"),
      StreamMessage::Done => write!(f, "done:"),
      StreamMessage::Metadata(s) => write!(f, "metadata:{s}"),
      StreamMessage::StartIndexFile { file_name } => {
        write!(f, "start_index_file:{}", file_name)
      },
      StreamMessage::EndIndexFile { file_name } => {
        write!(f, "end_index_file:{}", file_name)
      },
      StreamMessage::IndexFileError { file_name } => {
        write!(f, "index_file_error:{}", file_name)
      },
      StreamMessage::OnFollowUp(data) => {
        if let Ok(s) = serde_json::to_string(&data) {
          write!(f, "ai_follow_up:{}", s)
        } else {
          write!(f, "ai_follow_up:",)
        }
      },
      StreamMessage::AIResponseLimitExceeded => write!(f, "ai_response_limit:"),
      StreamMessage::AIImageResponseLimitExceeded => write!(f, "ai_image_response_limit:"),
      StreamMessage::AIMaxRequired(message) => write!(f, "ai_max_required:{}", message),
      StreamMessage::LocalAINotReady(message) => write!(f, "local_ai_not_ready:{}", message),
      StreamMessage::LocalAIDisabled(message) => write!(f, "local_ai_disabled:{}", message),
    }
  }
}
