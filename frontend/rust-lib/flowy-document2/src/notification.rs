use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const DOCUMENT_OBSERVABLE_SOURCE: &str = "Document";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum DocumentNotification {
  #[default]
  Unknown = 0,

  DidReceiveUpdate = 1,
}

impl std::convert::From<DocumentNotification> for i32 {
  fn from(notification: DocumentNotification) -> Self {
    notification as i32
  }
}
impl std::convert::From<i32> for DocumentNotification {
  fn from(notification: i32) -> Self {
    match notification {
      1 => DocumentNotification::DidReceiveUpdate,
      _ => DocumentNotification::Unknown,
    }
  }
}

pub(crate) fn send_notification(id: &str, ty: DocumentNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, DOCUMENT_OBSERVABLE_SOURCE)
}
