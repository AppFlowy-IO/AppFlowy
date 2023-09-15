use collab_define::reminder::{ObjectType, Reminder};

use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Clone)]
pub struct ReminderPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub scheduled_at: i64,

  #[pb(index = 3)]
  pub is_ack: bool,

  #[pb(index = 4)]
  pub ty: i64,

  #[pb(index = 5)]
  pub title: String,

  #[pb(index = 6)]
  pub message: String,

  #[pb(index = 7)]
  pub reminder_object_id: String,
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
      meta: Default::default(),
      object_id: value.reminder_object_id,
    }
  }
}

impl From<Reminder> for ReminderPB {
  fn from(value: Reminder) -> Self {
    Self {
      id: value.id,
      scheduled_at: value.scheduled_at,
      is_ack: value.is_ack,
      ty: value.ty as i64,
      title: value.title,
      message: value.message,
      reminder_object_id: value.object_id,
    }
  }
}

impl From<Vec<ReminderPB>> for RepeatedReminderPB {
  fn from(value: Vec<ReminderPB>) -> Self {
    Self { items: value }
  }
}
