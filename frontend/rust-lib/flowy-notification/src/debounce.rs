use crate::entities::SubscribeObject;
use crate::{send_subject, NotificationBuilder};
use dashmap::mapref::entry::Entry;
use dashmap::DashMap;
use lib_dispatch::prelude::ToBytes;
use tokio_util::sync::CancellationToken;

pub struct DebounceNotificationSender {
  debounce_in_millis: u64,
  cancel_token_by_subject: DashMap<String, CancellationToken>,
}

impl DebounceNotificationSender {
  pub fn new(debounce_in_millis: u64) -> Self {
    Self {
      debounce_in_millis,
      cancel_token_by_subject: DashMap::new(),
    }
  }

  pub fn send<T: Into<i32>, P: ToBytes>(&self, id: &str, ty: T, source: &str, payload: P) {
    let subject = NotificationBuilder::new(id, ty, source)
      .payload(payload)
      .build();
    self.send_subject(subject);
  }

  pub fn send_subject(&self, subject: SubscribeObject) {
    let subject_key = format!("{}-{}-{}", subject.source, subject.id, subject.ty);
    // remove the old cancel token and call cancel to stop the old task
    if let Entry::Occupied(entry) = self.cancel_token_by_subject.entry(subject_key.clone()) {
      let cancel_token = entry.get();
      cancel_token.cancel();
      entry.remove();
    }

    // insert a new cancel token
    let cancel_token = CancellationToken::new();
    self
      .cancel_token_by_subject
      .insert(subject_key.clone(), cancel_token.clone());
    let debounce_in_millis = self.debounce_in_millis;
    tokio::spawn(async move {
      if debounce_in_millis > 0 {
        tokio::time::sleep(std::time::Duration::from_millis(debounce_in_millis)).await;
      }

      if cancel_token.is_cancelled() {
        return;
      }
      send_subject(subject);
    });
  }
}
