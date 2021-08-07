use crate::core::{Attributes, AttributesData};
use derive_more::Display;

#[derive(Clone, Debug, Display, Hash, Eq, PartialEq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Attribute {
    #[display(fmt = "bold")]
    Bold,
    #[display(fmt = "italic")]
    Italic,
}

pub struct AttrsBuilder {
    inner: AttributesData,
}

impl AttrsBuilder {
    pub fn new() -> Self {
        Self {
            inner: AttributesData::default(),
        }
    }

    pub fn add(mut self, attribute: Attribute) -> Self {
        self.inner.add(attribute);
        self
    }

    pub fn remove(mut self, attribute: &Attribute) -> Self {
        self.inner.remove(attribute);
        self
    }

    pub fn bold(self, bold: bool) -> Self {
        match bold {
            true => self.add(Attribute::Bold),
            false => self.remove(&Attribute::Bold),
        }
    }

    pub fn italic(self, italic: bool) -> Self {
        match italic {
            true => self.add(Attribute::Italic),
            false => self.remove(&Attribute::Italic),
        }
    }

    pub fn build(self) -> Attributes { Attributes::Custom(self.inner) }
}
