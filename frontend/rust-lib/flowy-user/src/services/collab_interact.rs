use anyhow::Error;
use collab_entity::reminder::Reminder;

use lib_infra::future::FutureResult;

pub trait CollabInteract: Send + Sync + 'static {
  fn add_reminder(&self, reminder: Reminder) -> FutureResult<(), Error>;
  fn remove_reminder(&self, reminder_id: &str) -> FutureResult<(), Error>;
  fn update_reminder(&self, reminder: Reminder) -> FutureResult<(), Error>;
}

pub struct DefaultCollabInteract;
impl CollabInteract for DefaultCollabInteract {
  fn add_reminder(&self, _reminder: Reminder) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn remove_reminder(&self, _reminder_id: &str) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_reminder(&self, _reminder: Reminder) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }
}
