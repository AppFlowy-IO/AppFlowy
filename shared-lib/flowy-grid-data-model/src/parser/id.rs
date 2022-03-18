#[derive(Debug)]
pub struct NonEmptyId(pub String);

impl NonEmptyId {
    pub fn parse(s: String) -> Result<NonEmptyId, ()> {
        if s.trim().is_empty() {
            return Err(());
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for NonEmptyId {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
