use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct ImageData {
    image: String,
}

impl ToString for ImageData {
    fn to_string(&self) -> String {
        self.image.clone()
    }
}
