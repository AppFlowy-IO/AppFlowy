use unicode_segmentation::UnicodeSegmentation;
#[derive(Debug)]
pub struct AppDesc(pub String);

impl AppDesc {
    #[allow(dead_code)]
    pub fn parse(s: String) -> Result<AppDesc, String> {
        if s.graphemes(true).count() > 1024 {
            return Err("Workspace description too long".to_string());
        }

        Ok(Self(s))
    }
}

impl AsRef<str> for AppDesc {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
