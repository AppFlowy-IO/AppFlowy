use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct UserIcon(pub String);

impl UserIcon {
    pub fn parse(s: String) -> Result<UserIcon, ErrorCode> {
        Ok(Self(s))
    }
}

impl AsRef<str> for UserIcon {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
