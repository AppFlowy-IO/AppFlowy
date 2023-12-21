use tracing::instrument;

use crate::entities::UserProfilePB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_deps::entities::Authenticator;

use crate::manager::UserManager;
use crate::migrations::MigrationUser;
use crate::services::entities::Session;

const ANON_USER: &str = "anon_user";
impl UserManager {
  #[instrument(skip_all)]
  pub async fn get_migration_user(&self, auth_type: &Authenticator) -> Option<MigrationUser> {
    // Only migrate the data if the user is login in as a guest and sign up as a new user if the current
    // auth type is not [AuthType::Local].
    let session = self.get_session().ok()?;
    let user_profile = self
      .get_user_profile_from_disk(session.user_id)
      .await
      .ok()?;
    if user_profile.authenticator == Authenticator::Local && !auth_type.is_local() {
      Some(MigrationUser {
        user_profile,
        session,
      })
    } else {
      None
    }
  }

  pub fn set_anon_user(&self, session: Session) {
    let _ = self.store_preferences.set_object(ANON_USER, session);
  }

  pub async fn get_anon_user(&self) -> FlowyResult<UserProfilePB> {
    let anon_session = self
      .store_preferences
      .get_object::<Session>(ANON_USER)
      .ok_or(FlowyError::new(
        ErrorCode::RecordNotFound,
        "Anon user not found",
      ))?;
    let profile = self
      .get_user_profile_from_disk(anon_session.user_id)
      .await?;
    Ok(UserProfilePB::from(profile))
  }

  /// Opens a historical user's session based on their user ID, device ID, and authentication type.
  ///
  /// This function facilitates the re-opening of a user's session from historical tracking.
  /// It retrieves the user's workspace and establishes a new session for the user.
  ///
  pub async fn open_anon_user(&self) -> FlowyResult<()> {
    let anon_session = self
      .store_preferences
      .get_object::<Session>(ANON_USER)
      .ok_or(FlowyError::new(
        ErrorCode::RecordNotFound,
        "Anon user not found",
      ))?;
    self.set_session(Some(anon_session))?;
    Ok(())
  }
}
