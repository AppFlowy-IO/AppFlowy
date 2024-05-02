use std::sync::RwLock;

use crate::entities::SubscribeObject;
use lazy_static::lazy_static;
mod builder;
pub use builder::*;

mod debounce;
pub use debounce::*;

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
