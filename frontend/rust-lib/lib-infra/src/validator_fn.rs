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

#[macro_export]
/// Macro to implement a custom validator function for a regex expression.
/// This is intended to replace `validator` crate's own regex validator, which
/// isn't compatible with `fancy_regex`.
///
/// # Arguments:
///
/// - name of the validator function
/// - the `fancy_regex::Regex` object
/// - error message of the `ValidationError`
///
macro_rules! impl_regex_validator {
  ($validator: ident, $regex: expr, $error: expr) => {
    pub(crate) fn $validator(arg: &str) -> Result<(), ValidationError> {
      let check = $regex.is_match(arg).unwrap();

      if check {
        Ok(())
      } else {
        Err(ValidationError::new($error))
      }
    }
  };
}
