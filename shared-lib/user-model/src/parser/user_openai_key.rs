use crate::errors::UserErrorCode;

#[derive(Debug)]
pub struct UserOpenaiKey(pub String);

impl UserOpenaiKey {
  pub fn parse(s: String) -> Result<UserOpenaiKey, UserErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserOpenaiKey {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
