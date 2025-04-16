use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use uuid::Uuid;

pub const USER_SIGN_IN_URL: &str = "sign_in_url";
pub const USER_UUID: &str = "uuid";
pub const USER_EMAIL: &str = "email";
pub const USER_DEVICE_ID: &str = "device_id";

/// Represents a user that is currently using the server.
pub trait ServerUser: Send + Sync {
  /// different user might return different workspace id.
  fn workspace_id(&self) -> FlowyResult<Uuid>;

  fn user_id(&self) -> FlowyResult<i64>;

  fn get_sqlite_db(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}
