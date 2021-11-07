use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct WorkspaceId(pub String);

impl WorkspaceId {
    pub fn parse(s: String) -> Result<WorkspaceId, ErrorCode> {
        if s.trim().is_empty() {
            return Err(ErrorCode::WorkspaceIdInvalid);
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for WorkspaceId {
    fn as_ref(&self) -> &str { &self.0 }
}
