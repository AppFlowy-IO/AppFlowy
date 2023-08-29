use std::collections::HashMap;

use collab_define::reminder::{ObjectType, Reminder, ReminderMeta};

use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Clone)]
pub struct ReminderPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub object_id: String,

  #[pb(index = 3)]
  pub scheduled_at: i64,

  #[pb(index = 4)]
  pub is_ack: bool,

  #[pb(index = 5)]
  pub title: String,

  #[pb(index = 6)]
  pub message: String,

  #[pb(index = 7)]
  pub meta: HashMap<String, String>,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct RepeatedReminderPB {
  #[pb(index = 1)]
  pub items: Vec<ReminderPB>,
}

impl From<ReminderPB> for Reminder {
  fn from(value: ReminderPB) -> Self {
    Self {
      id: value.id,
      scheduled_at: value.scheduled_at,
      is_ack: value.is_ack,
      ty: ObjectType::Document,
      title: value.title,
      message: value.message,
      meta: ReminderMeta::from(value.meta),
      object_id: value.object_id,
    }
  }
}

impl From<Reminder> for ReminderPB {
  fn from(value: Reminder) -> Self {
    Self {
      id: value.id,
      object_id: value.object_id,
      scheduled_at: value.scheduled_at,
      is_ack: value.is_ack,
      title: value.title,
      message: value.message,
      meta: value.meta.into_inner(),
    }
  }
}

impl From<Vec<ReminderPB>> for RepeatedReminderPB {
  fn from(value: Vec<ReminderPB>) -> Self {
    Self { items: value }
  }
}

#[derive(ProtoBuf, Default, Clone)]
pub struct ReminderIdentifierPB {
  #[pb(index = 1)]
  pub id: String,
}
