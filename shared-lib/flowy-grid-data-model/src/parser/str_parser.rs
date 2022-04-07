use uuid::Uuid;

#[derive(Debug)]
pub struct NotEmptyUuid(pub String);

impl NotEmptyUuid {
    pub fn parse(s: String) -> Result<Self, String> {
        if s.trim().is_empty() {
            return Err("Input string is empty".to_owned());
        }
        debug_assert!(Uuid::parse_str(&s).is_ok());

        Ok(Self(s))
    }
}

impl AsRef<str> for NotEmptyUuid {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

#[derive(Debug)]
pub struct NotEmptyStr(pub String);

impl NotEmptyStr {
    pub fn parse(s: String) -> Result<Self, String> {
        if s.trim().is_empty() {
            return Err("Input string is empty".to_owned());
        }
        Ok(Self(s))
    }
}

impl AsRef<str> for NotEmptyStr {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
