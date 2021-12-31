use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct ViewIdentify(pub String);

impl ViewIdentify {
    pub fn parse(s: String) -> Result<ViewIdentify, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::ViewIdInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for ViewIdentify {
    fn as_ref(&self) -> &str { &self.0 }
}
