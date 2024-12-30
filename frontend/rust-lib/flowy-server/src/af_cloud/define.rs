use flowy_error::FlowyResult;

pub const USER_SIGN_IN_URL: &str = "sign_in_url";
pub const USER_UUID: &str = "uuid";
pub const USER_EMAIL: &str = "email";
pub const USER_DEVICE_ID: &str = "device_id";

/// Represents a user that is currently using the server.
pub trait ServerUser: Send + Sync {
  /// different user might return different workspace id.
  fn workspace_id(&self) -> FlowyResult<String>;
}
