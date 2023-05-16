use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct UserOpenaiKey(pub String);

impl UserOpenaiKey {
  pub fn parse(s: String) -> Result<UserOpenaiKey, ErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserOpenaiKey {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
