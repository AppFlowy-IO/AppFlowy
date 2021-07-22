#[derive(Debug)]
pub struct DocViewId(pub String);

impl DocViewId {
    pub fn parse(s: String) -> Result<DocViewId, String> {
        if s.trim().is_empty() {
            return Err(format!("Doc view id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}
