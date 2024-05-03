use crate::entities::SubscribeObject;
use crate::NOTIFICATION_SENDER;
use bytes::Bytes;
use lib_dispatch::prelude::ToBytes;

pub struct NotificationBuilder {
  /// This identifier is used to uniquely distinguish each notification. For instance, if the
  /// notification relates to a folder's view, the identifier could be the view's ID. The frontend
  /// uses this ID to link the notification with the relevant observable entity.
  id: String,
  payload: Option<Bytes>,
  error: Option<Bytes>,
  source: String,
  ty: i32,
}

impl NotificationBuilder {
  pub fn new<T: Into<i32>>(id: &str, ty: T, source: &str) -> Self {
    Self {
      id: id.to_owned(),
      ty: ty.into(),
      payload: None,
      error: None,
      source: source.to_owned(),
    }
  }

  pub fn payload<T>(mut self, payload: T) -> Self
  where
    T: ToBytes,
  {
    match payload.into_bytes() {
      Ok(bytes) => self.payload = Some(bytes),
      Err(e) => {
        tracing::error!("Set observable payload failed: {:?}", e);
      },
    }

    self
  }

  pub fn error<T>(mut self, error: T) -> Self
  where
    T: ToBytes,
  {
    match error.into_bytes() {
      Ok(bytes) => self.error = Some(bytes),
      Err(e) => {
        tracing::error!("Set observable error failed: {:?}", e);
      },
    }
    self
  }

  pub fn build(self) -> SubscribeObject {
    let payload = self.payload.map(|bytes| bytes.to_vec());
    let error = self.error.map(|bytes| bytes.to_vec());
    SubscribeObject {
      source: self.source,
      ty: self.ty,
      id: self.id,
      payload,
      error,
    }
  }

  pub fn send(self) {
    let payload = self.payload.map(|bytes| bytes.to_vec());
    let error = self.error.map(|bytes| bytes.to_vec());
    let subject = SubscribeObject {
      source: self.source,
      ty: self.ty,
      id: self.id,
      payload,
      error,
    };

    send_subject(subject);
  }
}

#[inline]
pub fn send_subject(subject: SubscribeObject) {
  match NOTIFICATION_SENDER.read() {
    Ok(read_guard) => read_guard.iter().for_each(|sender| {
      if let Err(e) = sender.send_subject(subject.clone()) {
        tracing::error!("Post notification failed: {}", e);
      }
    }),
    Err(err) => {
      tracing::error!("Read notification sender failed: {}", err);
    },
  }
}
