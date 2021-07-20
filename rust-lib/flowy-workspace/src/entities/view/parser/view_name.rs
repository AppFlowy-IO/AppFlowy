use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct ViewName(pub String);

impl ViewName {
    pub fn parse(s: String) -> Result<ViewName, String> {
        if s.trim().is_empty() {
            return Err(format!("View name can not be empty or whitespace"));
        }

        if s.graphemes(true).count() > 256 {
            return Err(format!("View name too long"));
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for ViewName {
    fn as_ref(&self) -> &str { &self.0 }
}
