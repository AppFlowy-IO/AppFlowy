use validator::ValidationError;

pub use auth::*;
pub use realtime::*;
pub use reminder::*;
pub use user_profile::*;
pub use user_setting::*;
pub use workspace_member::*;

pub mod auth;
pub mod date_time;
pub mod parser;
pub mod realtime;
mod reminder;
mod user_profile;
mod user_setting;
mod workspace_member;

pub fn required_not_empty_str(s: &str) -> Result<(), ValidationError> {
  if s.is_empty() {
    return Err(ValidationError::new("should not be empty string"));
  }
  Ok(())
}
