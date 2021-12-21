use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct ViewId(pub String);

impl ViewId {
    pub fn parse(s: String) -> Result<ViewId, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::ViewIdInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for ViewId {
    fn as_ref(&self) -> &str { &self.0 }
}
