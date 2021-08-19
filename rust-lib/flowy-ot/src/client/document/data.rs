use crate::{client::DocumentData, errors::OTError};
use serde::{Deserialize, Serialize};

impl<T: AsRef<str>> DocumentData for T {
    fn into_string(self) -> Result<String, OTError> { Ok(self.as_ref().to_string()) }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ImageData {
    image: String,
}

impl DocumentData for ImageData {
    fn into_string(self) -> Result<String, OTError> {
        let s = serde_json::to_string(&self)?;
        Ok(s)
    }
}
