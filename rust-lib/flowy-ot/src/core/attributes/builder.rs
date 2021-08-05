use crate::core::{Attributes, AttributesData};
use derive_more::Display;
const REMOVE_FLAG: &'static str = "";
pub(crate) fn should_remove(s: &str) -> bool { s == REMOVE_FLAG }

#[derive(Clone, Display)]
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

    pub fn add_attribute(mut self, attribute: Attribute) -> Self {
        self.inner
            .insert(format!("{}", attribute), "true".to_owned());
        self
    }

    pub fn remove_attribute(mut self, attribute: Attribute) -> Self {
        self.inner
            .insert(format!("{}", attribute), REMOVE_FLAG.to_owned());
        self
    }

    pub fn bold(self, bold: bool) -> Self {
        match bold {
            true => self.add_attribute(Attribute::Bold),
            false => self.remove_attribute(Attribute::Bold),
        }
    }

    pub fn italic(self, italic: bool) -> Self {
        match italic {
            true => self.add_attribute(Attribute::Italic),
            false => self.remove_attribute(Attribute::Italic),
        }
    }

    pub fn build(self) -> Attributes { Attributes::Custom(self.inner) }
}
