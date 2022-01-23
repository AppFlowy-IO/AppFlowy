use crate::errors::ErrorCode;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct ViewName(pub String);

impl ViewName {
    pub fn parse(s: String) -> Result<ViewName, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::ViewNameInvalid);
        }

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
