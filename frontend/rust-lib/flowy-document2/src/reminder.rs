use collab_entity::reminder::Reminder;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DocumentReminderAction {
  Add { reminder: DocumentReminder },
  Remove { reminder_id: String },
  Update { reminder: DocumentReminder },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DocumentReminder {
  document_id: String, // defines the necessary fields for a reminder
}

impl TryFrom<Reminder> for DocumentReminder {
  type Error = serde_json::Error;

  fn try_from(value: Reminder) -> Result<Self, Self::Error> {
    serde_json::from_value(json!(value.meta.into_inner()))
  }
}
