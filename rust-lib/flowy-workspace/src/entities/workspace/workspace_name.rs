#[derive(Debug)]
pub struct WorkspaceName(pub String);

impl WorkspaceName {
    pub fn parse(s: String) -> Result<WorkspaceName, String> {
        if s.trim().is_empty() {
            return Err(format!("Workspace name can not be empty or whitespace"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for WorkspaceName {
    fn as_ref(&self) -> &str { &self.0 }
}
