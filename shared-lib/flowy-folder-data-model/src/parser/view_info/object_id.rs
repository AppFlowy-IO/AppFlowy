use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct ObjectId(pub String);

impl ObjectId {
    pub fn parse(s: String) -> Result<ObjectId, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::UnexpectedEmptyString);
        }
        Ok(Self(s))
    }
}

impl AsRef<str> for ObjectId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
