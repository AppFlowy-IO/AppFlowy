use crate::errors::UserErrorCode;

#[derive(Debug)]
pub struct UserWorkspace(pub String);

impl UserWorkspace {
  pub fn parse(s: String) -> Result<UserWorkspace, UserErrorCode> {
    let is_empty_or_whitespace = s.trim().is_empty();
    if is_empty_or_whitespace {
      return Err(UserErrorCode::WorkspaceIdInvalid);
    }
    Ok(Self(s))
  }
}

impl AsRef<str> for UserWorkspace {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
