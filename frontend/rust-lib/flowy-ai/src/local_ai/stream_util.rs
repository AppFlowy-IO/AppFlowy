use appflowy_plugin::error::PluginError;
use bytes::Bytes;
use flowy_ai_pub::cloud::QuestionStreamValue;
use flowy_error::FlowyError;
use futures::{ready, Stream};
use pin_project::pin_project;
use std::pin::Pin;
use std::task::{Context, Poll};

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
    return match ready!(this.stream.as_mut().poll_next(cx)) {
      Some(Ok(bytes)) => match String::from_utf8(bytes.to_vec()) {
        Ok(s) => Poll::Ready(Some(Ok(QuestionStreamValue::Answer { value: s }))),
        Err(err) => Poll::Ready(Some(Err(FlowyError::internal().with_context(err)))),
      },
      Some(Err(err)) => Poll::Ready(Some(Err(FlowyError::local_ai().with_context(err)))),
      None => Poll::Ready(None),
    };
  }
}
