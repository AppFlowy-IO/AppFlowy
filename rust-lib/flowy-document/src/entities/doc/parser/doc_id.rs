#[derive(Debug)]
pub struct DocId(pub String);

impl DocId {
    pub fn parse(s: String) -> Result<DocId, String> {
        if s.trim().is_empty() {
            return Err(format!("Doc id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for DocId {
    fn as_ref(&self) -> &str { &self.0 }
}
