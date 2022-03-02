use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct ViewExtensionData(pub String);

impl ViewExtensionData {
    pub fn parse(s: String) -> Result<ViewExtensionData, ErrorCode> {
        Ok(Self(s))
    }
}

impl AsRef<str> for ViewExtensionData {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
