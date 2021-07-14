#[derive(Debug)]
pub struct AppId(pub String);

impl AppId {
    pub fn parse(s: String) -> Result<AppId, String> {
        if s.trim().is_empty() {
            return Err(format!("App id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppId {
    fn as_ref(&self) -> &str { &self.0 }
}
