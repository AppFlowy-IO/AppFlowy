use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const DOCUMENT_OBSERVABLE_SOURCE: &str = "Document";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum DocumentNotification {
  #[default]
  Unknown = 0,

  DidReceiveUpdate = 1,
  DidUpdateDocumentSnapshotState = 2,
  DidUpdateDocumentSyncState = 3,
  DidUpdateDocumentAwarenessState = 4,
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
      2 => DocumentNotification::DidUpdateDocumentSnapshotState,
      3 => DocumentNotification::DidUpdateDocumentSyncState,
      4 => DocumentNotification::DidUpdateDocumentAwarenessState,
      _ => DocumentNotification::Unknown,
    }
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: DocumentNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, DOCUMENT_OBSERVABLE_SOURCE)
}
