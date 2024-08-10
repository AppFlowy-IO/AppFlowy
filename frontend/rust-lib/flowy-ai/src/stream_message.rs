use std::fmt::Display;

pub enum StreamMessage {
  MessageId { message_id: i64 },
  IndexStart,
  IndexEnd,
  Text { text: String },
  Done,
  StartIndexFile { file_name: String },
  EndIndexFile { file_name: String },
  IndexFileError { file_name: String },
}
impl Display for StreamMessage {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      StreamMessage::MessageId { message_id } => write!(f, "message_id:{}", message_id),
      StreamMessage::IndexStart => write!(f, "index_start:"),
      StreamMessage::IndexEnd => write!(f, "index_end"),
      StreamMessage::Text { text } => {
        write!(f, "data:{}", text)
      },
      StreamMessage::Done => write!(f, "done:"),
      StreamMessage::StartIndexFile { file_name } => {
        write!(f, "start_index_file:{}", file_name)
      },
      StreamMessage::EndIndexFile { file_name } => {
        write!(f, "end_index_file:{}", file_name)
      },
      StreamMessage::IndexFileError { file_name } => {
        write!(f, "index_file_error:{}", file_name)
      },
    }
  }
}
