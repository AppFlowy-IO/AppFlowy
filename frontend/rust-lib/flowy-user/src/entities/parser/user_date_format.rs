use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct UserDateFormat(pub String);

impl UserDateFormat {
  pub fn parse(s: String) -> Result<UserDateFormat, ErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserDateFormat {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
