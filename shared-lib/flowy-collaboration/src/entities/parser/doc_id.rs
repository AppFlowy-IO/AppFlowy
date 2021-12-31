#[derive(Debug)]
pub struct DocumentIdentify(pub String);

impl DocumentIdentify {
    pub fn parse(s: String) -> Result<DocumentIdentify, String> {
        if s.trim().is_empty() {
            return Err("Doc id can not be empty or whitespace".to_string());
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for DocumentIdentify {
    fn as_ref(&self) -> &str { &self.0 }
}
