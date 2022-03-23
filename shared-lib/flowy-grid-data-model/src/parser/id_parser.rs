use uuid::Uuid;

#[derive(Debug)]
pub struct NotEmptyUuid(pub String);

impl NotEmptyUuid {
    pub fn parse(s: String) -> Result<NotEmptyUuid, ()> {
        debug_assert!(Uuid::parse_str(&s).is_ok());

        if s.trim().is_empty() {
            return Err(());
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for NotEmptyUuid {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
