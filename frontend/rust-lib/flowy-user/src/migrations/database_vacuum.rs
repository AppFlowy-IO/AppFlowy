use crate::services::db::UserDB;
use crate::services::user_sql::vacuum_database;
use flowy_sqlite::kv::StorePreferences;
use std::sync::Arc;
use tracing::{error, info};

const SQLITE_VACUUM_04: &str = "sqlite_vacuum_04";

pub fn vacuum_database_if_need(
  uid: i64,
  user_db: &Arc<UserDB>,
  store_preferences: &Arc<StorePreferences>,
) {
  if !store_preferences.get_bool(SQLITE_VACUUM_04) {
    let _ = store_preferences.set_bool(SQLITE_VACUUM_04, true);

    if let Ok(conn) = user_db.get_connection(uid) {
      info!("vacuum database 04");
      if let Err(err) = vacuum_database(conn) {
        error!("vacuum database error: {:?}", err);
      }
    }
  }
}
