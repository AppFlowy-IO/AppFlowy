#[derive(Debug)]
pub struct ViewId(pub String);

impl ViewId {
    pub fn parse(s: String) -> Result<ViewId, String> {
        if s.trim().is_empty() {
            return Err(format!("View id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for ViewId {
    fn as_ref(&self) -> &str { &self.0 }
}
