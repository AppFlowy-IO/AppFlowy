use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct AppName(pub String);

impl AppName {
    pub fn parse(s: String) -> Result<AppName, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::AppNameInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppName {
    fn as_ref(&self) -> &str { &self.0 }
}
