#[derive(Debug)]
pub struct WorkspaceId(pub String);

impl WorkspaceId {
    pub fn parse(s: String) -> Result<WorkspaceId, String> {
        if s.trim().is_empty() {
            return Err(format!("Workspace id can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for WorkspaceId {
    fn as_ref(&self) -> &str { &self.0 }
}
