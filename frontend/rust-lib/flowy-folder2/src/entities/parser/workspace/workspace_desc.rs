use flowy_error::ErrorCode;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct WorkspaceDesc(pub String);

impl WorkspaceDesc {
  pub fn parse(s: String) -> Result<WorkspaceDesc, ErrorCode> {
    if s.graphemes(true).count() > 1024 {
      return Err(ErrorCode::WorkspaceNameTooLong);
    }

    Ok(Self(s))
  }
}

impl AsRef<str> for WorkspaceDesc {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
