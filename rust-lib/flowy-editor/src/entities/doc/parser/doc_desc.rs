use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct DocDesc(pub String);

impl DocDesc {
    pub fn parse(s: String) -> Result<DocDesc, String> {
        if s.graphemes(true).count() > 1000 {
            return Err(format!("Doc desc too long"));
        }

        Ok(Self(s))
    }
}
