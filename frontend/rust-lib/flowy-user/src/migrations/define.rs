use crate::services::session_serde::Session;
use flowy_user_deps::entities::UserProfile;

pub struct UserMigrationContext {
  pub user_profile: UserProfile,
  pub session: Session,
}
