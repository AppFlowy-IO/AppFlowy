use flowy_error::ErrorCode;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct ViewName(pub String);

impl ViewName {
  pub fn parse(s: String) -> Result<ViewName, ErrorCode> {
    if s.graphemes(true).count() > 256 {
      return Err(ErrorCode::ViewNameTooLong);
    }

    Ok(Self(s))
  }
}

impl AsRef<str> for ViewName {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
