use crate::entities::trash::TrashType;
use std::convert::TryFrom;

#[derive(Debug)]
pub struct TrashTypeParser(pub i32);

impl TrashTypeParser {
    pub fn parse(value: i32) -> Result<i32, String> {
        let _ = TrashType::try_from(value)?;
        Ok(value)
    }
}

impl AsRef<i32> for TrashTypeParser {
    fn as_ref(&self) -> &i32 { &self.0 }
}
