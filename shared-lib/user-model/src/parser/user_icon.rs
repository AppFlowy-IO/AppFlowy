use crate::errors::UserErrorCode;

#[derive(Debug)]
pub struct UserIcon(pub String);

impl UserIcon {
  pub fn parse(s: String) -> Result<UserIcon, UserErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserIcon {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
