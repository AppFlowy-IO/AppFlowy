use crate::errors::ErrorCode;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct ViewDesc(pub String);

impl ViewDesc {
    pub fn parse(s: String) -> Result<ViewDesc, ErrorCode> {
        if s.graphemes(true).count() > 1000 {
            return Err(ErrorCode::ViewDescTooLong);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for ViewDesc {
    fn as_ref(&self) -> &str { &self.0 }
}
