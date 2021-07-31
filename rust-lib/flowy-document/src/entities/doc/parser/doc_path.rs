#[derive(Debug)]
pub struct DocPath(pub String);

impl DocPath {
    pub fn parse(s: String) -> Result<DocPath, String> {
        if s.trim().is_empty() {
            return Err(format!("Doc path can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}
