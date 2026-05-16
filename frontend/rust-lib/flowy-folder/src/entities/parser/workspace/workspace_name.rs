use flowy_error::ErrorCode;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct WorkspaceName(pub String);

impl WorkspaceName {
  pub fn parse(s: String) -> Result<WorkspaceName, ErrorCode> {
    if s.trim().is_empty() {
      return Err(ErrorCode::WorkspaceNameInvalid);
    }

    if s.graphemes(true).count() > 256 {
      return Err(ErrorCode::WorkspaceNameTooLong);
    }

    Ok(Self(s))
  }
}

impl AsRef<str> for WorkspaceName {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
