use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct UserTimeFormat(pub String);

impl UserTimeFormat {
  pub fn parse(s: String) -> Result<UserTimeFormat, ErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserTimeFormat {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
