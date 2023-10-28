use validator::ValidationError;

pub use user_email::*;
pub use user_icon::*;
pub use user_id::*;
pub use user_name::*;
pub use user_openai_key::*;
pub use user_password::*;
pub use user_stability_ai_key::*;

// https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/
mod user_email;
mod user_icon;
mod user_id;
mod user_name;
mod user_openai_key;
mod user_password;
mod user_stability_ai_key;

pub fn validate_not_empty_str(s: &str) -> Result<(), ValidationError> {
  if s.is_empty() {
    return Err(ValidationError::new("should not be empty string"));
  }
  Ok(())
}
