use std::sync::RwLock;

use bytes::Bytes;
use lazy_static::lazy_static;

use lib_dispatch::prelude::ToBytes;

use crate::entities::SubscribeObject;

pub mod entities;
mod protobuf;

lazy_static! {
  static ref NOTIFICATION_SENDER: RwLock<Vec<Box<dyn NotificationSender>>> = RwLock::new(vec![]);
}

/// Register a notification sender. The sender will be alive until the process exits.
/// Flutter integration test or Tauri hot reload might cause register multiple times.
/// So before register a new sender, you might need to unregister the old one. Currently,
/// Just remove all senders by calling `unregister_all_notification_sender`.
pub fn register_notification_sender<T: NotificationSender>(sender: T) {
  let box_sender = Box::new(sender);
  match NOTIFICATION_SENDER.write() {
    Ok(mut write_guard) => write_guard.push(box_sender),
    Err(err) => tracing::error!("Failed to push notification sender: {:?}", err),
  }
}

pub fn unregister_all_notification_sender() {
  match NOTIFICATION_SENDER.write() {
    Ok(mut write_guard) => write_guard.clear(),
    Err(err) => tracing::error!("Failed to remove all notification senders: {:?}", err),
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
