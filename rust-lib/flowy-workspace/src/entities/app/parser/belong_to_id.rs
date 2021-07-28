#[derive(Debug)]
pub struct BelongToId(pub String);

impl BelongToId {
    pub fn parse(s: String) -> Result<BelongToId, String> {
        if s.trim().is_empty() {
            return Err(format!("App id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for BelongToId {
    fn as_ref(&self) -> &str { &self.0 }
}
