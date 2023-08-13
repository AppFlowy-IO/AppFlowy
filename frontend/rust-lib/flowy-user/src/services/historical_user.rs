use diesel::RunQueryDsl;

use flowy_error::FlowyResult;
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::{query_dsl::*, ExpressionMethods};
use flowy_user_deps::entities::{AuthType, UserWorkspace};
use lib_infra::util::timestamp;

use crate::services::entities::{HistoricalUser, HistoricalUsers, Session};
use crate::services::user_workspace_sql::UserWorkspaceTable;
use crate::services::UserManager;

const HISTORICAL_USER: &str = "af_historical_users";
impl UserManager {
  pub fn log_user(
    &self,
    uid: i64,
    device_id: &str,
    user_name: String,
    auth_type: &AuthType,
    storage_path: String,
  ) {
    let mut logger_users = self
      .store_preferences
      .get_object::<HistoricalUsers>(HISTORICAL_USER)
      .unwrap_or_default();
    logger_users.add_user(HistoricalUser {
      user_id: uid,
      user_name,
      auth_type: auth_type.clone(),
      sign_in_timestamp: timestamp(),
      storage_path,
      device_id: device_id.to_string(),
    });
    let _ = self
      .store_preferences
      .set_object(HISTORICAL_USER, logger_users);
  }

  pub fn get_historical_users(&self) -> Vec<HistoricalUser> {
    let mut users = self
      .store_preferences
      .get_object::<HistoricalUsers>(HISTORICAL_USER)
      .unwrap_or_default()
      .users;
    users.sort_by(|a, b| b.sign_in_timestamp.cmp(&a.sign_in_timestamp));
    users
  }

  pub fn open_historical_user(
    &self,
    uid: i64,
    device_id: String,
    auth_type: AuthType,
  ) -> FlowyResult<()> {
    let conn = self.db_connection(uid)?;
    let row = user_workspace_table::dsl::user_workspace_table
      .filter(user_workspace_table::uid.eq(uid))
      .first::<UserWorkspaceTable>(&*conn)?;
    let user_workspace = UserWorkspace::from(row);
    let session = Session {
      user_id: uid,
      device_id,
      user_workspace,
    };
    debug_assert!(auth_type.is_local());
    self.cloud_services.set_auth_type(auth_type);
    self.set_current_session(Some(session))?;
    Ok(())
  }
}
