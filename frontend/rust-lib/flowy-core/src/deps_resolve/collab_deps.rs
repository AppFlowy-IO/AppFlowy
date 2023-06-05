use appflowy_integrate::{CollabSnapshot, MutexCollab, PersistenceError, SnapshotDB};
use flowy_user::services::UserSession;
use std::sync::Arc;

pub struct SnapshotDBImpl {
  user_session: Arc<UserSession>,
}

impl SnapshotDB for SnapshotDBImpl {
  fn get_snapshots(&self, uid: i64, object_id: &str) -> Vec<CollabSnapshot> {
    todo!()
  }

  fn create_snapshot(
    &self,
    uid: i64,
    object_id: &str,
    collab: Arc<MutexCollab>,
  ) -> Result<(), PersistenceError> {
    todo!()
  }
}
