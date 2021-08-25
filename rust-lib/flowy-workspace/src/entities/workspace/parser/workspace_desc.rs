use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct WorkspaceDesc(pub String);

impl WorkspaceDesc {
    pub fn parse(s: String) -> Result<WorkspaceDesc, String> {
        if s.graphemes(true).count() > 1024 {
            return Err(format!("Workspace description too long"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for WorkspaceDesc {
    fn as_ref(&self) -> &str { &self.0 }
}
