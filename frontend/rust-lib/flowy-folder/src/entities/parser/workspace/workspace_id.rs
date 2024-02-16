use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct WorkspaceIdentify(pub String);

impl WorkspaceIdentify {
  pub fn parse(s: String) -> Result<WorkspaceIdentify, ErrorCode> {
    if s.trim().is_empty() {
      return Err(ErrorCode::WorkspaceInitializeError);
    }

    Ok(Self(s))
  }
}

impl AsRef<str> for WorkspaceIdentify {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
