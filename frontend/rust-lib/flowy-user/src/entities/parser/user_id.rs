use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct UserId(pub String);

impl UserId {
  pub fn parse(s: String) -> Result<UserId, ErrorCode> {
    let is_empty_or_whitespace = s.trim().is_empty();
    if is_empty_or_whitespace {
      return Err(ErrorCode::UserIdInvalid);
    }
    Ok(Self(s))
  }
}

impl AsRef<str> for UserId {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
