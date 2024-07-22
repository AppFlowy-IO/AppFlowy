use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const OBSERVABLE_SOURCE: &str = "storage";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum StorageNotification {
  #[default]
  FileStorageLimitExceeded = 0,
}

impl std::convert::From<StorageNotification> for i32 {
  fn from(notification: StorageNotification) -> Self {
    notification as i32
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn make_notification(ty: StorageNotification) -> NotificationBuilder {
  NotificationBuilder::new("appflowy_file_storage_notification", ty, OBSERVABLE_SOURCE)
}
