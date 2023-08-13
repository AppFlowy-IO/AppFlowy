use flowy_user_deps::entities::UserProfile;

use crate::services::entities::Session;

pub struct UserMigrationContext {
  pub user_profile: UserProfile,
  pub session: Session,
}
