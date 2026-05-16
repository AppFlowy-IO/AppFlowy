use allo_isolate::Isolate;
use bytes::Bytes;
use flowy_notification::entities::SubscribeObject;
use flowy_notification::NotificationSender;
use std::convert::TryInto;

pub struct DartNotificationSender {
  isolate: Isolate,
}

impl DartNotificationSender {
  pub fn new(port: i64) -> Self {
    Self {
      isolate: Isolate::new(port),
    }
  }
}

impl NotificationSender for DartNotificationSender {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
    let bytes: Bytes = subject.try_into().unwrap();
    self.isolate.post(bytes.to_vec());
    Ok(())
  }
}
