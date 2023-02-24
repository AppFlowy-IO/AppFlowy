pub mod entities;
mod protobuf;

use crate::entities::SubscribeObject;
use bytes::Bytes;
use lazy_static::lazy_static;
use lib_dispatch::prelude::ToBytes;
use std::sync::RwLock;

lazy_static! {
  static ref NOTIFICATION_SENDER: RwLock<Vec<Box<dyn NotificationSender>>> = RwLock::new(vec![]);
}

pub fn register_notification_sender<T: NotificationSender>(sender: T) {
  let box_sender = Box::new(sender);
  match NOTIFICATION_SENDER.write() {
    Ok(mut write_guard) => write_guard.push(box_sender),
    Err(err) => tracing::error!("Failed to push notification sender: {:?}", err),
  }
}

pub trait NotificationSender: Send + Sync + 'static {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String>;
}

pub struct NotificationBuilder {
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
}
