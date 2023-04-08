pub mod entities;
mod protobuf;

use crate::entities::SubscribeObject;
use bytes::Bytes;
use lazy_static::lazy_static;
use lib_dispatch::prelude::ToBytes;
use std::{
  collections::{hash_map::Values, HashMap},
  sync::RwLock,
};

lazy_static! {
  static ref NOTIFICATION_SENDER: RwLock<NotificationSenderStore> =
    RwLock::new(NotificationSenderStore::new());
}

struct NotificationSenderStore {
  idx: usize,
  senders: HashMap<usize, Box<dyn NotificationSender>>,
}

impl NotificationSenderStore {
  pub fn new() -> Self {
    Self {
      idx: 0,
      senders: HashMap::new(),
    }
  }

  pub fn next_id(&self) -> usize {
    self.idx
  }

  pub fn push(&mut self, sender: Box<dyn NotificationSender>) -> usize {
    let id = self.idx;
    self.idx += 1;
    self.senders.insert(id, sender);
    id
  }

  pub fn remove(&mut self, id: &usize) {
    self.senders.remove(id);
  }

  pub fn iter(&self) -> Values<usize, Box<dyn NotificationSender>> {
    self.senders.values()
  }
}

pub fn register_notification_sender<T: NotificationSender>(sender: T) -> Option<usize> {
  let box_sender = Box::new(sender);
  match NOTIFICATION_SENDER.write() {
    Ok(mut write_guard) => Some(write_guard.push(box_sender)),
    Err(err) => {
      tracing::error!("Failed to push notification sender: {:?}", err);
      None
    },
  }
}

pub fn remove_notification_sender(id: &usize) {
  match NOTIFICATION_SENDER.write() {
    Ok(mut write_guard) => write_guard.remove(id),
    Err(err) => tracing::error!("Failed to remove notification sender: {:?}", err),
  }
}

pub fn next_notification_sender_id() -> Option<usize> {
  match NOTIFICATION_SENDER.read() {
    Ok(read_guard) => Some(read_guard.next_id()),
    Err(err) => {
      tracing::error!("Failed to get next sender id: {}", err);
      None
    },
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
