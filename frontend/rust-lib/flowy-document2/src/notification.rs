use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;


const OBSERVABLE_CATEGORY: &str = "Document";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum DocumentNotification {
  Unknown = 0,

  DidReceiveUpdate = 1,
}

impl std::default::Default for DocumentNotification {
  fn default() -> Self {
    DocumentNotification::Unknown
  }
}

impl std::convert::From<DocumentNotification> for i32 {
  fn from(notification: DocumentNotification) -> Self {
    notification as i32
  }
}

pub(crate) fn send_notification(id: &str, ty: DocumentNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
