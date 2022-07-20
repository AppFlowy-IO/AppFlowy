use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct AppIdentify(pub String);

impl AppIdentify {
    pub fn parse(s: String) -> Result<AppIdentify, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::AppIdInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppIdentify {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
