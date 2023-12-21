use crate::services::entities::Session;
use flowy_user_deps::entities::UserProfile;

pub mod document_empty_content;
pub mod migration;
pub mod session_migration;
mod util;
pub mod workspace_and_favorite_v1;

#[derive(Clone, Debug)]
pub struct MigrationUser {
  pub user_profile: UserProfile,
  pub session: Session,
}
