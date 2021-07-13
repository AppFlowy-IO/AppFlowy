#[derive(Debug)]
pub struct AppName(pub String);

impl AppName {
    pub fn parse(s: String) -> Result<AppName, String> {
        if s.trim().is_empty() {
            return Err(format!("Workspace can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppName {
    fn as_ref(&self) -> &str { &self.0 }
}
