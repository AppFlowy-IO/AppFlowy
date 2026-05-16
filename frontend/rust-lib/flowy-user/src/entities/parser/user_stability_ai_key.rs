use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct UserStabilityAIKey(pub String);

impl UserStabilityAIKey {
  pub fn parse(s: String) -> Result<UserStabilityAIKey, ErrorCode> {
    Ok(Self(s))
  }
}

impl AsRef<str> for UserStabilityAIKey {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
