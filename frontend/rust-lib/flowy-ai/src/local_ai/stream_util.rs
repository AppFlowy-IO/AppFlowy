use appflowy_plugin::error::PluginError;
use bytes::Bytes;
use flowy_ai_pub::cloud::QuestionStreamValue;
use flowy_error::FlowyError;
use futures::{ready, Stream};
use pin_project::pin_project;
use serde_json::Value;
use std::pin::Pin;
use std::task::{Context, Poll};
use tracing::error;

#[pin_project]
pub struct LocalAIStreamAdaptor {
  stream: Pin<Box<dyn Stream<Item = Result<Bytes, PluginError>> + Send>>,
  buffer: Vec<u8>,
}

impl LocalAIStreamAdaptor {
  pub fn new<S>(stream: S) -> Self
  where
    S: Stream<Item = Result<Bytes, PluginError>> + Send + 'static,
  {
    LocalAIStreamAdaptor {
      stream: Box::pin(stream),
      buffer: Vec::new(),
    }
  }
}

impl Stream for LocalAIStreamAdaptor {
  type Item = Result<QuestionStreamValue, FlowyError>;

  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
    let this = self.project();
    match ready!(this.stream.as_mut().poll_next(cx)) {
      Some(Ok(bytes)) => match String::from_utf8(bytes.to_vec()) {
        Ok(s) => Poll::Ready(Some(Ok(QuestionStreamValue::Answer { value: s }))),
        Err(err) => Poll::Ready(Some(Err(FlowyError::internal().with_context(err)))),
      },
      Some(Err(err)) => Poll::Ready(Some(Err(FlowyError::local_ai().with_context(err)))),
      None => Poll::Ready(None),
    }
  }
}
pub const STEAM_METADATA_KEY: &str = "0";
pub const STEAM_ANSWER_KEY: &str = "1";

#[pin_project]
pub struct QuestionStream {
  stream: Pin<Box<dyn Stream<Item = Result<Value, PluginError>> + Send>>,
  buffer: Vec<u8>,
}

impl QuestionStream {
  pub fn new<S>(stream: S) -> Self
  where
    S: Stream<Item = Result<Value, PluginError>> + Send + 'static,
  {
    QuestionStream {
      stream: Box::pin(stream),
      buffer: Vec::new(),
    }
  }
}

impl Stream for QuestionStream {
  type Item = Result<QuestionStreamValue, FlowyError>;

  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
    let this = self.project();

    match ready!(this.stream.as_mut().poll_next(cx)) {
      Some(Ok(value)) => match value {
        Value::Object(mut value) => {
          if let Some(metadata) = value.remove(STEAM_METADATA_KEY) {
            return Poll::Ready(Some(Ok(QuestionStreamValue::Metadata { value: metadata })));
          }

          if let Some(answer) = value
            .remove(STEAM_ANSWER_KEY)
            .and_then(|s| s.as_str().map(ToString::to_string))
          {
            return Poll::Ready(Some(Ok(QuestionStreamValue::Answer { value: answer })));
          }

          error!("Invalid streaming value: {:?}", value);
          Poll::Ready(None)
        },
        _ => {
          error!("Unexpected JSON value type: {:?}", value);
          Poll::Ready(None)
        },
      },
      Some(Err(err)) => Poll::Ready(Some(Err(FlowyError::local_ai().with_context(err)))),
      None => Poll::Ready(None),
    }
  }
}
