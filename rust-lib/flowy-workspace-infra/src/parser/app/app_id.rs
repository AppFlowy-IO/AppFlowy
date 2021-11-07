use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct AppId(pub String);

impl AppId {
    pub fn parse(s: String) -> Result<AppId, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::AppIdInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppId {
    fn as_ref(&self) -> &str { &self.0 }
}
