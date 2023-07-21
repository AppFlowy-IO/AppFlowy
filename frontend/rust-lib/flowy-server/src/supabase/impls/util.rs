use std::sync::{Arc, Weak};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::supabase::PostgresServer;

pub fn try_upgrade_server(
  weak_server: FlowyResult<Weak<PostgresServer>>,
) -> FlowyResult<Arc<PostgresServer>> {
  match weak_server?.upgrade() {
    None => Err(FlowyError::new(
      ErrorCode::PgDatabaseError,
      "Server is close",
    )),
    Some(server) => Ok(server),
  }
}
