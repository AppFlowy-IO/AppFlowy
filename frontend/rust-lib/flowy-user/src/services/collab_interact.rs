use anyhow::Error;
use collab_entity::reminder::Reminder;
use lib_infra::async_trait::async_trait;

#[async_trait]
pub trait CollabInteract: Send + Sync + 'static {
  async fn add_reminder(&self, _reminder: Reminder) -> Result<(), Error> {
    Ok(())
  }
  async fn remove_reminder(&self, _reminder_id: &str) -> Result<(), Error> {
    Ok(())
  }
  async fn update_reminder(&self, _reminder: Reminder) -> Result<(), Error> {
    Ok(())
  }
}

pub struct DefaultCollabInteract;

#[async_trait]
impl CollabInteract for DefaultCollabInteract {}
