#[derive(Debug)]
pub struct DocName(pub String);

impl DocName {
    pub fn parse(s: String) -> Result<DocName, String> {
        if s.trim().is_empty() {
            return Err(format!("Doc name can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}
