use crate::{
  entities::{FieldPB, FieldUpdateNotificationPB},
  notification::{send_notification, DatabaseNotification},
};

pub fn notify_did_update_field_to_single_field(field_id: &str, notification: FieldPB) {
  send_notification(field_id, DatabaseNotification::DidUpdateField)
    .payload(notification)
    .send();
}

pub fn notify_did_update_field_to_views(
  views: Vec<String>,
  notification: FieldUpdateNotificationPB,
) {
  for view_id in views {
    send_notification(&view_id, DatabaseNotification::DidUpdateFields)
      .payload(notification.clone())
      .send();
  }
}
