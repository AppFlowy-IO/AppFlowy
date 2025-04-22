use std::sync::Arc;
use tracing::instrument;

use crate::entities::UserProfilePB;
use crate::user_manager::UserManager;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::entities::AuthType;

use crate::migrations::AnonUser;
use flowy_user_pub::session::Session;

pub const ANON_USER: &str = "anon_user";
impl UserManager {
  #[instrument(skip_all)]
  pub async fn get_migration_user(&self, current_authenticator: &AuthType) -> Option<AnonUser> {
    // No need to migrate if the user is already local
    if current_authenticator.is_local() {
      return None;
    }

    let session = self.get_session().ok()?;
    let user_profile = self
      .get_user_profile_from_disk(session.user_id, &session.user_workspace.id)
      .await
      .ok()?;

    if user_profile.auth_type.is_local() {
      Some(AnonUser { session })
    } else {
      None
    }
  }

  pub fn set_anon_user(&self, session: &Session) {
    let _ = self.store_preferences.set_object(ANON_USER, session);
  }

  pub fn remove_anon_user(&self) {
    self.store_preferences.remove(ANON_USER);
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
      .get_user_profile_from_disk(anon_session.user_id, &anon_session.user_workspace.id)
      .await?;
    Ok(UserProfilePB::from(profile))
  }

  pub fn get_anon_user_id(&self) -> FlowyResult<i64> {
    let anon_session = self
      .store_preferences
      .get_object::<Session>(ANON_USER)
      .ok_or(FlowyError::new(
        ErrorCode::RecordNotFound,
        "Anon user not found",
      ))?;

    Ok(anon_session.user_id)
  }

  /// Opens a historical user's session based on their user ID, device ID, and authentication type.
  ///
  /// This function facilitates the re-opening of a user's session from historical tracking.
  /// It retrieves the user's workspace and establishes a new session for the user.
  ///
  pub async fn open_anon_user(&self) -> FlowyResult<()> {
    let anon_session = self
      .store_preferences
      .get_object::<Arc<Session>>(ANON_USER)
      .ok_or(FlowyError::new(
        ErrorCode::RecordNotFound,
        "Anon user not found",
      ))?;
    self.authenticate_user.set_session(Some(anon_session))?;
    Ok(())
  }
}
