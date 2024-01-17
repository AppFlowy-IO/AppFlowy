use std::path::Path;
use validator::ValidationError;

pub fn required_not_empty_str(s: &str) -> Result<(), ValidationError> {
  if s.is_empty() {
    return Err(ValidationError::new("should not be empty string"));
  }
  Ok(())
}

pub fn required_valid_path(s: &str) -> Result<(), ValidationError> {
  let path = Path::new(s);
  match (path.is_absolute(), path.exists()) {
    (true, true) => Ok(()),
    (_, _) => Err(ValidationError::new("invalid_path")),
  }
}
