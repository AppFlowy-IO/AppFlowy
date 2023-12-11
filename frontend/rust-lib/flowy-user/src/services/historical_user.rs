use diesel::RunQueryDsl;
use tracing::instrument;

use flowy_error::FlowyResult;
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::{query_dsl::*, ExpressionMethods};
use flowy_user_deps::entities::{Authenticator, UserWorkspace};
use lib_infra::util::timestamp;

use crate::manager::UserManager;
use crate::migrations::MigrationUser;
use crate::services::entities::{HistoricalUser, HistoricalUsers, Session};
use crate::services::user_workspace_sql::UserWorkspaceTable;

const HISTORICAL_USER: &str = "af_historical_users";
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
  /// Logs a user's details for historical tracking.
  ///
  /// This function adds a user's details to a local historical tracking system, useful for
  /// keeping track of past sign-ins or any other historical activities.
  ///
  /// # Parameters
  /// - `uid`: The user ID.
  /// - `device_id`: The ID of the device the user is using.
  /// - `user_name`: The name of the user.
  /// - `auth_type`: The type of authentication used.
  /// - `storage_path`: Path where user data is stored.
  ///
  pub fn add_historical_user(
    &self,
    uid: i64,
    device_id: &str,
    user_name: String,
    authenticator: &Authenticator,
    storage_path: String,
  ) {
    let mut logger_users = self
      .store_preferences
      .get_object::<HistoricalUsers>(HISTORICAL_USER)
      .unwrap_or_default();
    logger_users.add_user(HistoricalUser {
      user_id: uid,
      user_name,
      auth_type: authenticator.clone(),
      sign_in_timestamp: timestamp(),
      storage_path,
      device_id: device_id.to_string(),
    });
    let _ = self
      .store_preferences
      .set_object(HISTORICAL_USER, logger_users);
  }

  /// Fetches a list of historical users, sorted by their sign-in timestamp.
  ///
  /// This function retrieves a list of users who have previously been logged for historical tracking.
  pub fn get_historical_users(&self) -> Vec<HistoricalUser> {
    let mut users = self
      .store_preferences
      .get_object::<HistoricalUsers>(HISTORICAL_USER)
      .unwrap_or_default()
      .users;
    users.sort_by(|a, b| b.sign_in_timestamp.cmp(&a.sign_in_timestamp));
    users
  }

  /// Opens a historical user's session based on their user ID, device ID, and authentication type.
  ///
  /// This function facilitates the re-opening of a user's session from historical tracking.
  /// It retrieves the user's workspace and establishes a new session for the user.
  ///
  pub async fn open_historical_user(&self, uid: i64, auth_type: Authenticator) -> FlowyResult<()> {
    debug_assert!(auth_type.is_local());
    self.update_authenticator(&auth_type).await;
    let conn = self.db_connection(uid)?;
    let row = user_workspace_table::dsl::user_workspace_table
      .filter(user_workspace_table::uid.eq(uid))
      .first::<UserWorkspaceTable>(&*conn)?;
    let user_workspace = UserWorkspace::from(row);
    let session = Session {
      user_id: uid,
      user_workspace,
    };
    self.set_session(Some(session))?;
    Ok(())
  }
}
