use flowy_user_deps::entities::UserProfile;

use crate::services::entities::Session;

#[derive(Clone)]
pub struct MigrationUser {
  pub user_profile: UserProfile,
  pub session: Session,
}
